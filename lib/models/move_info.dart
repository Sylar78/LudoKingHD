import 'player_color.dart';

/// Carries information about the last pawn move for the hop animation.
class LastMoveInfo {
  final int playerIdx;
  final int pawnIdx;
  final int fromPosition; // -1 = was in base
  final int toPosition;
  final PlayerColor color;
  final List<int> path; // ordered list of positions visited (including final)

  const LastMoveInfo({
    required this.playerIdx,
    required this.pawnIdx,
    required this.fromPosition,
    required this.toPosition,
    required this.color,
    required this.path,
  });
}

/// One pawn sent back to base after a capture.
class CapturedPawnInfo {
  final int playerIdx;
  final int pawnIdx;
  final int fromPosition; // usually on outer path
  final int toPosition; // base = -1
  final PlayerColor color;

  const CapturedPawnInfo({
    required this.playerIdx,
    required this.pawnIdx,
    required this.fromPosition,
    required this.toPosition,
    required this.color,
  });
}

/// Visual effect payload for a capture: red halo on the capture cell + slides.
class CaptureEffectInfo {
  final int captureCellPosition;
  final List<CapturedPawnInfo> capturedPawns;

  const CaptureEffectInfo({
    required this.captureCellPosition,
    required this.capturedPawns,
  });
}
