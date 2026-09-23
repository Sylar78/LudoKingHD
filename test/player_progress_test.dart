// L'avancee affichee sous chaque joueur, qui a remplace la cagnotte en pieces.

import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_king_hd/models/player.dart';
import 'package:ludo_king_hd/models/player_color.dart';

void main() {
  group('Avancee d\'un joueur', () {
    test('elle part de zero, tous les pions en base', () {
      for (final couleur in PlayerColor.values) {
        final joueur = Player(color: couleur, type: PlayerType.human);
        expect(joueur.progress, 0.0, reason: couleur.name);
      }
    });

    test('elle vaut 1 quand les quatre pions sont au centre', () {
      final joueur = Player(color: PlayerColor.blue, type: PlayerType.human);
      for (final pion in joueur.pawns) {
        pion.position = 105;
      }
      expect(joueur.allPawnsHome, isTrue);
      expect(joueur.progress, 1.0);
    });

    test('un pion qui sort compte pour un pas, quelle que soit la couleur', () {
      for (final couleur in PlayerColor.values) {
        final joueur = Player(color: couleur, type: PlayerType.human);
        joueur.pawns.first.position = couleur.startPosition;
        expect(joueur.stepsDone(joueur.pawns.first), 1, reason: couleur.name);
      }
    });

    test('le tour du plateau vaut 52 pas, le centre 58', () {
      final joueur = Player(color: PlayerColor.red, type: PlayerType.human);
      final pion = joueur.pawns.first;

      pion.position = PlayerColor.red.homeEntryPosition;
      expect(joueur.stepsDone(pion), 52);

      pion.position = 100; // premiere case de la colonne
      expect(joueur.stepsDone(pion), 53);

      pion.position = 105; // le centre
      expect(joueur.stepsDone(pion), Player.stepsPerPawn);
    });

    test('elle monte toujours quand un pion avance', () {
      final joueur = Player(color: PlayerColor.green, type: PlayerType.human);
      final pion = joueur.pawns.first;
      var precedente = joueur.progress;

      // Un tour complet, de la sortie jusqu'au centre.
      for (var pas = 0; pas <= 51; pas++) {
        pion.position = (PlayerColor.green.startPosition + pas) % 52;
        expect(joueur.progress, greaterThan(precedente),
            reason: 'pas $pas sur le chemin exterieur');
        precedente = joueur.progress;
      }
      for (var cell = 100; cell <= 105; cell++) {
        pion.position = cell;
        expect(joueur.progress, greaterThan(precedente),
            reason: 'case $cell de la colonne');
        precedente = joueur.progress;
      }
    });
  });
}
