import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/move_info.dart';
import '../providers/game_provider.dart';
import '../utils/board_layout.dart';
import 'ludo_board_painter.dart';

class LudoBoardWidget extends StatefulWidget {
  const LudoBoardWidget({super.key});

  @override
  State<LudoBoardWidget> createState() => _LudoBoardWidgetState();
}

class _LudoBoardWidgetState extends State<LudoBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  GameProvider? _provider;
  LastMoveInfo? _activeMove;
  int _lastAnimatedVersion = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _activeMove = null);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = context.read<GameProvider>();
    if (newProvider != _provider) {
      _provider?.removeListener(_onGameChange);
      _provider = newProvider;
      _provider!.addListener(_onGameChange);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onGameChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onGameChange() {
    if (!mounted) return;
    final p = _provider!;
    if (p.moveVersion > _lastAnimatedVersion && p.lastMove != null) {
      _lastAnimatedVersion = p.moveVersion;
      final move = p.lastMove!;
      // Each cell-step gets 200 ms, total duration capped at 1.4 s
      final steps = move.path.isEmpty ? 1 : move.path.length;
      _ctrl.duration = Duration(milliseconds: (steps * 200).clamp(200, 1400));
      setState(() => _activeMove = move);
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.state;

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTapUp: (state == null || _ctrl.isAnimating)
            ? null
            : (details) => _handleTap(details, context, state),
        child: CustomPaint(
          painter: LudoBoardPainter(
            state: state,
            highlightedPawnIndices: state?.movablePawnIndices ?? [],
            activeMove: _ctrl.isAnimating ? _activeMove : null,
            animProgress: _ctrl.value,
          ),
        ),
      ),
    );
  }

  void _handleTap(
      TapUpDetails details, BuildContext context, GameState state) {
    if (state.phase != GamePhase.choosingPawn) return;
    final provider = context.read<GameProvider>();
    final boxSize = (context.findRenderObject() as RenderBox).size;
    final cellSize = boxSize.width / 15;
    final tapPos = details.localPosition;

    final player = state.currentPlayer;

    for (final pawnIdx in state.movablePawnIndices) {
      final pawn = player.pawns[pawnIdx];
      double cx, cy;
      if (pawn.isInBase) {
        final off =
            BoardLayout.basePositionOffset(pawn.color, pawnIdx, cellSize);
        cx = off.$1;
        cy = off.$2;
      } else {
        final off =
            BoardLayout.positionToOffset(pawn.position, pawn.color, cellSize);
        cx = off.$1;
        cy = off.$2;
      }
      final dist = (tapPos - Offset(cx, cy)).distance;
      if (dist < cellSize * 0.6) {
        provider.movePawn(pawnIdx);
        return;
      }
    }
  }
}
