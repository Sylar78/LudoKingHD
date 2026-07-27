import 'dart:math';
import '../models/board_constants.dart';
import '../models/game_state.dart';
import '../models/pawn.dart';
import '../models/player.dart';
import '../models/player_color.dart';

class GameEngine {
  static final _random = Random();

  // ── Dice ────────────────────────────────────────────────────────────────
  static int rollDice() => _random.nextInt(6) + 1;

  // ── Outer-path arithmetic (52 squares) ─────────────────────────────────

  /// Returns the absolute outer-path position for a given player after moving
  /// [steps] from [currentPosition]. The path is 0..51, wrapping.
  static int advanceOnOuterPath(int currentPosition, int steps) =>
      (currentPosition + steps) % 52;

  /// How many steps remain for a pawn to reach the home entry of its colour.
  static int stepsToHomeEntry(Pawn pawn) {
    final entry = pawn.color.homeEntryPosition;
    final start = pawn.color.startPosition;
    final pos = pawn.position;

    // distance already travelled on outer path
    int travelled;
    if (pos >= start) {
      travelled = pos - start;
    } else {
      travelled = 52 - start + pos;
    }
    // total needed to reach entry
    int total;
    if (entry >= start) {
      total = entry - start;
    } else {
      total = 52 - start + entry;
    }
    return total - travelled; // remaining steps to reach entry
  }

  // ── Moving a pawn ───────────────────────────────────────────────────────

  /// Compute the new position for [pawn] after rolling [dice].
  /// Returns null if the move is impossible (exact count rule for home).
  static int? computeNewPosition(Pawn pawn, int dice) {
    if (pawn.isInBase) {
      // Can only exit on a 6
      return dice == 6 ? pawn.color.startPosition : null;
    }

    if (pawn.isHome) return null; // already home

    if (pawn.isInHomeColumn) {
      final newPos = pawn.position + dice;
      if (newPos > 105) return null; // overshoot – exact count required
      return newPos;
    }

    // On outer path
    final remaining = stepsToHomeEntry(pawn);
    if (dice == remaining) {
      // Enters first cell of home column
      return 100;
    }
    if (dice < remaining) {
      return advanceOnOuterPath(pawn.position, dice);
    }
    // dice > remaining: would need to enter home column
    final excess = dice - remaining;
    final homePos = 100 + excess;
    if (homePos > 105) return null; // overshoot
    return homePos;
  }
  /// Returns every position the [pawn] passes through (inclusive of final)
  /// when [dice] is rolled. Used for step-by-step hop animation.
  static List<int> computeMovePath(Pawn pawn, int dice) {
    if (pawn.isInBase) {
      return dice == 6 ? [pawn.color.startPosition] : [];
    }
    if (pawn.isHome) return [];

    if (pawn.isInHomeColumn) {
      final result = <int>[];
      for (int i = 1; i <= dice; i++) {
        final next = pawn.position + i;
        if (next > 105) break;
        result.add(next);
      }
      return result;
    }

    // On outer path
    final remaining = stepsToHomeEntry(pawn);
    if (remaining <= 0) {
      final result = <int>[];
      for (int i = 1; i <= dice && 100 + i <= 105; i++) result.add(100 + i);
      return result;
    }

    final result = <int>[];
    if (dice < remaining) {
      for (int i = 1; i <= dice; i++) {
        result.add(advanceOnOuterPath(pawn.position, i));
      }
    } else {
      // Walk outer path up to (but not including) home entry
      for (int i = 1; i < remaining; i++) {
        result.add(advanceOnOuterPath(pawn.position, i));
      }
      result.add(100); // first home-column cell
      final excess = dice - remaining;
      for (int i = 1; i <= excess && 100 + i <= 105; i++) {
        result.add(100 + i);
      }
    }
    return result;
  }
  // ── Capture logic ───────────────────────────────────────────────────────

  /// If the [pawn] lands on an outer-path square occupied by opponent pawns,
  /// those pawns are sent back to base.
  ///
  /// Returns a record list describing captured pawns for UI animation.
  static List<({
    int playerIdx,
    int pawnIdx,
    PlayerColor color,
    int fromPosition
  })> resolveCaptures(Pawn pawn, GameState state) {
    if (!pawn.isOnOuterPath) return [];
    if (safeZones.contains(pawn.position)) return [];

    final captured = <({
      int playerIdx,
      int pawnIdx,
      PlayerColor color,
      int fromPosition
    })>[];

    for (int pi = 0; pi < state.players.length; pi++) {
      final player = state.players[pi];
      if (player.color == pawn.color) continue;
      for (final op in player.pawns) {
        if (op.position == pawn.position && op.isOnOuterPath) {
          captured.add((
            playerIdx: pi,
            pawnIdx: op.index,
            color: op.color,
            fromPosition: op.position,
          ));
          op.position = -1; // send back to base
        }
      }
    }
    return captured;
  }

  // ── Blocking (stacking) ─────────────────────────────────────────────────

  /// Returns true if the square [pos] is blocked by two or more pawns of
  /// another player (a block that cannot be passed or captured).
  static bool isBlockedByOpponent(int pos, PlayerColor moverColor,
      GameState state) {
    if (pos < 0 || pos > 51) return false; // only on outer path
    for (final player in state.players) {
      if (player.color == moverColor) continue;
      final count = player.pawns.where((p) => p.position == pos).length;
      if (count >= 2) return true;
    }
    return false;
  }

  // ── Compute movable pawns ────────────────────────────────────────────────

  /// Given the current dice roll, returns a list of pawn indices (within
  /// the current player's pawn list) that have a valid move.
  static List<int> movablePawns(Player player, int dice, GameState state) {
    final result = <int>[];
    for (int i = 0; i < player.pawns.length; i++) {
      final pawn = player.pawns[i];
      final newPos = computeNewPosition(pawn, dice);
      if (newPos == null) continue;
      // Check block
      if (newPos >= 0 && newPos <= 51 &&
          isBlockedByOpponent(newPos, player.color, state)) {
        continue;
      }
      result.add(i);
    }
    return result;
  }

  // ── Turn helpers ────────────────────────────────────────────────────────

  /// Returns true if the player earns an extra roll after this move.
  static bool earnsExtraRoll(
      {required int dice,
      required bool captured,
      required bool reachedHome}) {
    return dice == 6 || captured || reachedHome;
  }

  /// Advance to the next non-finished player.
  static int nextPlayerIndex(GameState state) {
    int next = (state.currentPlayerIndex + 1) % state.players.length;
    int tries = 0;
    while (state.players[next].hasFinished &&
        tries < state.players.length) {
      next = (next + 1) % state.players.length;
      tries++;
    }
    return next;
  }

  // ── AI move selection ───────────────────────────────────────────────────

  /// Simple AI: prefer captures > furthest pawn > exit base.
  static int chooseAiPawn(Player player, int dice, GameState state) {
    final movable = movablePawns(player, dice, state);
    if (movable.isEmpty) return -1;

    // 1. Prefer a capture
    for (final i in movable) {
      final pawn = player.pawns[i];
      final newPos = computeNewPosition(pawn, dice);
      if (newPos == null) continue;
      if (newPos >= 0 && newPos <= 51 && !safeZones.contains(newPos)) {
        for (final op in state.players) {
          if (op.color == player.color) continue;
          if (op.pawns.any((p) => p.position == newPos)) return i;
        }
      }
    }

    // 2. Prefer exiting base if dice == 6
    if (dice == 6) {
      for (final i in movable) {
        if (player.pawns[i].isInBase) return i;
      }
    }

    // 3. Furthest advanced pawn
    int bestIdx = movable.first;
    int bestProgress = _progressOf(player.pawns[bestIdx]);
    for (final i in movable.skip(1)) {
      final prog = _progressOf(player.pawns[i]);
      if (prog > bestProgress) {
        bestProgress = prog;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  static int _progressOf(Pawn pawn) {
    if (pawn.isInBase) return -1;
    if (pawn.isHome) return 200;
    if (pawn.isInHomeColumn) return pawn.position;
    return pawn.position;
  }
}
