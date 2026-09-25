import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/move_info.dart';
import '../models/player.dart';
import '../models/player_color.dart';
import '../utils/game_engine.dart';

class GameProvider extends ChangeNotifier {
  GameState? _state;

  GameState? get state => _state;

  bool _diceRolling = false;
  bool get diceRolling => _diceRolling;

  // ── Move animation tracking ──────────────────────────────────────────────
  int _moveVersion = 0;
  int get moveVersion => _moveVersion;

  LastMoveInfo? _lastMove;
  LastMoveInfo? get lastMove => _lastMove;

  int _captureVersion = 0;
  int get captureVersion => _captureVersion;

  CaptureEffectInfo? _lastCaptureEffect;
  CaptureEffectInfo? get lastCaptureEffect => _lastCaptureEffect;

  // ── Start ────────────────────────────────────────────────────────────────

  void startGame(GameMode mode, List<PlayerColor> colors) {
    _state = GameState.initial(mode, colors);
    _state!.message = "${_state!.currentPlayer.color.name} commence !";
    notifyListeners();
  }

  // ── Roll dice ────────────────────────────────────────────────────────────

  Future<void> rollDice() async {
    final s = _state;
    if (s == null) return;
    if (s.hasRolled || s.phase != GamePhase.rolling) return;

    _diceRolling = true;
    notifyListeners();

    // Animate dice (fake rolling for 600ms)
    await Future.delayed(const Duration(milliseconds: 600));

    final value = GameEngine.rollDice();
    _diceRolling = false;

    s.diceValue = value;
    s.hasRolled = true;

    // Three consecutive sixes → forfeit
    if (value == 6) {
      s.currentPlayer.consecutiveSixes++;
      if (s.currentPlayer.consecutiveSixes >= 3) {
        s.currentPlayer.consecutiveSixes = 0;
        _endTurn(
            raison:
                "Trois 6 de suite : tour annulé pour ${s.currentPlayer.color.name}.");
        notifyListeners();
        if (s.currentPlayer.type == PlayerType.computer) {
          await _triggerAiTurn();
        }
        return;
      }
    } else {
      s.currentPlayer.consecutiveSixes = 0;
    }

    final movable = GameEngine.movablePawns(s.currentPlayer, value, s);

    if (movable.isEmpty) {
      _endTurn(
          raison:
              "Aucun coup possible pour ${s.currentPlayer.color.name} avec un $value.");
      notifyListeners();
      // Auto-advance AI
      if (s.currentPlayer.type == PlayerType.computer) {
        await _triggerAiTurn();
      }
      return;
    }

    // Human QoL: auto-play only when there is exactly one pawn in play
    // (others still in base, or already home) and exactly one legal move.
    final pawnsInPlay = s.currentPlayer.pawns
        .where((p) => !p.isInBase && !p.isHome)
        .length;
    if (s.currentPlayer.type == PlayerType.human &&
        movable.length == 1 &&
        pawnsInPlay <= 1) {
      s.movablePawnIndices = movable;
      s.phase = GamePhase.choosingPawn;
      s.message =
          "${s.currentPlayer.color.name} : coup unique, déplacement automatique.";
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 180));
      movePawn(movable.first);
      return;
    }

    s.movablePawnIndices = movable;
    s.phase = GamePhase.choosingPawn;
    s.message = "${s.currentPlayer.color.name} : choisissez un pion.";
    notifyListeners();

    // AI auto-chooses
    if (s.currentPlayer.type == PlayerType.computer) {
      await Future.delayed(const Duration(milliseconds: 700));
      final aiChoice = GameEngine.chooseAiPawn(s.currentPlayer, value, s);
      if (aiChoice >= 0) movePawn(aiChoice);
    }
  }

  // ── Move pawn ────────────────────────────────────────────────────────────

  void movePawn(int pawnIndex) {
    final s = _state;
    if (s == null) return;
    if (!s.movablePawnIndices.contains(pawnIndex)) return;

    final player = s.currentPlayer;
    final pawn = player.pawns[pawnIndex];
    final newPos = GameEngine.computeNewPosition(pawn, s.diceValue);
    if (newPos == null) return;

    // Record move info BEFORE updating position (for animation)
    _moveVersion++;
    _lastMove = LastMoveInfo(
      playerIdx: s.currentPlayerIndex,
      pawnIdx: pawnIndex,
      fromPosition: pawn.position,
      toPosition: newPos,
      color: player.color,
      path: GameEngine.computeMovePath(pawn, s.diceValue),
    );

    pawn.position = newPos;

    final capturedPawns = GameEngine.resolveCaptures(pawn, s);
    final captured = capturedPawns.isNotEmpty;
    if (captured) {
      _captureVersion++;
      _lastCaptureEffect = CaptureEffectInfo(
        captureCellPosition: pawn.position,
        capturedPawns: capturedPawns
            .map(
              (c) => CapturedPawnInfo(
                playerIdx: c.playerIdx,
                pawnIdx: c.pawnIdx,
                fromPosition: c.fromPosition,
                toPosition: -1,
                color: c.color,
              ),
            )
            .toList(growable: false),
      );
    }
    final reachedHome = pawn.isHome;

    // Check if player finished
    if (player.allPawnsHome && !player.hasFinished) {
      player.hasFinished = true;
      s.finishedPlayerIndices.add(s.currentPlayerIndex);
      player.finishRank = s.finishedPlayerIndices.length;
      s.message = "🏆 ${player.color.name} a gagné !";
      s.phase = GamePhase.gameOver;
      s.winnerIndex = s.currentPlayerIndex;
      notifyListeners();
      return;
    }

    // Extra roll?
    final extra = GameEngine.earnsExtraRoll(
        dice: s.diceValue, captured: captured, reachedHome: reachedHome);

    if (extra && !player.hasFinished) {
      s.hasRolled = false;
      s.movablePawnIndices = [];
      s.phase = GamePhase.rolling;
      s.message =
          "${player.color.name} rejoue ! (${captured ? 'capture' : reachedHome ? 'arrivée' : '6'})";
    } else {
      _endTurn();
    }

    notifyListeners();

    // AI continues
    if (s.phase == GamePhase.rolling &&
        s.currentPlayer.type == PlayerType.computer) {
      _triggerAiTurn();
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  /// Passe la main. [raison] explique pourquoi le tour s'arrête.
  ///
  /// Sans ce paramètre, le message posé juste avant l'appel était écrasé par
  /// « Tour de X. » : le joueur ne voyait jamais qu'il n'avait aucun coup
  /// possible, ni qu'il venait de faire trois 6.
  void _endTurn({String? raison}) {
    final s = _state!;
    s.hasRolled = false;
    s.movablePawnIndices = [];
    s.phase = GamePhase.rolling;
    s.currentPlayerIndex = GameEngine.nextPlayerIndex(s);
    final suite = "Tour de ${s.currentPlayer.color.name}.";
    s.message = raison == null ? suite : "$raison $suite";
  }

  Future<void> _triggerAiTurn() async {
    await Future.delayed(const Duration(milliseconds: 900));
    await rollDice();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void reset() {
    _state = null;
    notifyListeners();
  }
}
