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
