import 'pawn.dart';
import 'player_color.dart';

enum PlayerType { human, computer }

class Player {
  final PlayerColor color;
  final PlayerType type;
  final List<Pawn> pawns;
  int coins;

  int consecutiveSixes = 0;
  bool hasFinished = false;
  int finishRank = 0; // 1 = winner, etc.

  Player({required this.color, required this.type})
      : pawns = List.generate(4, (i) => Pawn(color: color, index: i)),
        coins = _startCoins(color);

  static int _startCoins(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:    return 2820;
      case PlayerColor.blue:   return 3750;
      case PlayerColor.green:  return 5150;
      case PlayerColor.yellow: return 1700;
    }
  }

  bool get allPawnsHome => pawns.every((p) => p.isHome);

  List<Pawn> get pawnsInBase => pawns.where((p) => p.isInBase).toList();
  List<Pawn> get pawnsOnBoard =>
      pawns.where((p) => !p.isInBase && !p.isHome).toList();
  List<Pawn> get pawnsAtHome => pawns.where((p) => p.isHome).toList();
}
