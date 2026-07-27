import 'player_color.dart';

/// A pawn belongs to a player and has a position on the board.
///
/// Position encoding:
///   -1          → in base (not yet on board)
///   0..51       → outer path (52 squares, shared)
///   100..105    → home column (6 squares, colour-specific; 105 = centre)
class Pawn {
  final PlayerColor color;
  final int index; // 0..3 within the player

  int position; // -1 = base, 0-51 = outer, 100-105 = home column

  Pawn({required this.color, required this.index}) : position = -1;

  bool get isInBase => position == -1;
  bool get isHome => position == 105;
  bool get isOnOuterPath => position >= 0 && position <= 51;
  bool get isInHomeColumn => position >= 100 && position <= 105;

  Pawn copyWith({int? position}) {
    final p = Pawn(color: color, index: index);
    p.position = position ?? this.position;
    return p;
  }

  @override
  String toString() => '${color.name}[${index + 1}]@$position';
}
