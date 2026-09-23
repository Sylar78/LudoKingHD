import 'pawn.dart';
import 'player_color.dart';

enum PlayerType { human, computer }

class Player {
  final PlayerColor color;
  final PlayerType type;
  final List<Pawn> pawns;

  int consecutiveSixes = 0;
  bool hasFinished = false;
  int finishRank = 0; // 1 = winner, etc.

  Player({required this.color, required this.type})
      : pawns = List.generate(4, (i) => Pawn(color: color, index: i));

  // Il y avait ici une reserve de pieces, differente par couleur et jamais
  // modifiee ensuite : l'interface affichait « 2.8k », « 5.2k »... a cote de
  // chaque joueur, des chiffres qui ne voulaient rien dire. Supprimee, au
  // profit de l'avancee reelle ci-dessous.

  bool get allPawnsHome => pawns.every((p) => p.isHome);

  List<Pawn> get pawnsInBase => pawns.where((p) => p.isInBase).toList();
  List<Pawn> get pawnsOnBoard =>
      pawns.where((p) => !p.isInBase && !p.isHome).toList();
  List<Pawn> get pawnsAtHome => pawns.where((p) => p.isHome).toList();

  /// L'avancee du joueur, de 0 a 1.
  ///
  /// Un pion fait 58 pas de la base au centre : 1 pour sortir, 51 pour faire
  /// le tour jusqu'a l'entree de sa colonne, 6 dans la colonne.
  static const int stepsPerPawn = 58;

  int stepsDone(Pawn pawn) {
    if (pawn.isInBase) return 0;
    if (pawn.isInHomeColumn) return 52 + (pawn.position - 99);
    final depart = color.startPosition;
    final parcouru = pawn.position >= depart
        ? pawn.position - depart
        : 52 - depart + pawn.position;
    return parcouru + 1;
  }

  double get progress {
    final total = pawns.fold<int>(0, (somme, p) => somme + stepsDone(p));
    return (total / (stepsPerPawn * pawns.length)).clamp(0.0, 1.0);
  }
}
