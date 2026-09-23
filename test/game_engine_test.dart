// Tests des regles du plateau, sans widget ni animation.
//
// Ils remplacent le test compteur du modele Flutter, qui referencait une
// classe `MyApp` inexistante ici : `flutter test` echouait, et les workflows
// de publication refusent de deposer quoi que ce soit tant que les tests ne
// passent pas. Un test d'ecran serait ici fragile, les menus portant des
// animations en boucle qui laissent un minuteur en attente.

import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_king_hd/models/pawn.dart';
import 'package:ludo_king_hd/models/player_color.dart';
import 'package:ludo_king_hd/utils/game_engine.dart';

Pawn pionA(PlayerColor couleur, int position) {
  final p = Pawn(color: couleur, index: 0);
  p.position = position;
  return p;
}

void main() {
  group('Sortie de la base', () {
    test('un pion ne sort de la base que sur un 6', () {
      final pion = Pawn(color: PlayerColor.red, index: 0);
      expect(pion.isInBase, isTrue);
      for (var de = 1; de <= 5; de++) {
        expect(GameEngine.computeNewPosition(pion, de), isNull);
      }
      expect(GameEngine.computeNewPosition(pion, 6),
          PlayerColor.red.startPosition);
    });
  });

  group('Chemin exterieur', () {
    test('la progression boucle sur 52 cases', () {
      expect(GameEngine.advanceOnOuterPath(50, 3), 1);
      expect(GameEngine.advanceOnOuterPath(0, 52), 0);
    });

    test('un pion qui vient de sortir a 51 pas avant sa colonne', () {
      for (final couleur in PlayerColor.values) {
        final pion = pionA(couleur, couleur.startPosition);
        expect(GameEngine.stepsToHomeEntry(pion), 51,
            reason: 'couleur ${couleur.name}');
      }
    });

    test('un de trop petit avance simplement', () {
      final pion = pionA(PlayerColor.blue, 13);
      expect(GameEngine.computeNewPosition(pion, 3), 16);
    });
  });

  group('Entree dans la colonne de maison', () {
    test('le compte exact amene sur la premiere case de la colonne', () {
      final pion = pionA(PlayerColor.red, 48);
      // 48 → 51 = 3 pas jusqu'a l'entree.
      expect(GameEngine.stepsToHomeEntry(pion), 3);
      expect(GameEngine.computeNewPosition(pion, 3), 100);
    });

    test('un de plus grand entre plus loin dans la colonne', () {
      final pion = pionA(PlayerColor.red, 48);
      expect(GameEngine.computeNewPosition(pion, 5), 102);
    });
  });

  group('Arrivee au centre', () {
    test('le centre ne se prend qu\'au compte exact', () {
      final pion = pionA(PlayerColor.green, 103);
      expect(GameEngine.computeNewPosition(pion, 2), 105);
      expect(GameEngine.computeNewPosition(pion, 3), isNull);
    });

    test('un pion arrive ne bouge plus', () {
      final pion = pionA(PlayerColor.yellow, 105);
      expect(pion.isHome, isTrue);
      for (var de = 1; de <= 6; de++) {
        expect(GameEngine.computeNewPosition(pion, de), isNull);
      }
    });
  });

  group('De', () {
    test('le tirage reste entre 1 et 6', () {
      for (var i = 0; i < 300; i++) {
        final de = GameEngine.rollDice();
        expect(de, inInclusiveRange(1, 6));
      }
    });
  });
}
