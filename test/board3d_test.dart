// Le plateau 3D ne connait de la partie que ce que Flutter lui envoie, et
// retrouve les cases dans sa propre copie de la grille. Ces tests gardent
// les deux cotes d'accord.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_king_hd/models/board_constants.dart';
import 'package:ludo_king_hd/models/game_state.dart';
import 'package:ludo_king_hd/models/move_info.dart';
import 'package:ludo_king_hd/models/player_color.dart';
import 'package:ludo_king_hd/utils/board_layout.dart';
import 'package:ludo_king_hd/widgets/board3d/board_snapshot.dart';

List<List<int>> cellules(List<(int, int)> cases) => [
      for (final c in cases) [c.$1, c.$2]
    ];

void main() {
  group('Grille de la scene 3D (board3d/src/layout.json)', () {
    final grille =
        jsonDecode(File('board3d/src/layout.json').readAsStringSync())
            as Map<String, dynamic>;

    test('le parcours exterieur est celui de BoardLayout', () {
      expect(grille['outerPath'], cellules(BoardLayout.outerPath));
    });

    test('les colonnes d\'arrivee et les bases sont celles de BoardLayout', () {
      for (final couleur in PlayerColor.values) {
        final cle = colorKey(couleur);
        expect(grille['homeColumns'][cle],
            cellules(BoardLayout.homeColumns[couleur]!),
            reason: 'colonne $cle');
        expect(grille['basePositions'][cle],
            cellules(BoardLayout.basePositions[couleur]!),
            reason: 'base $cle');
        expect(grille['startPositions'][cle], couleur.startPosition);
      }
    });

    test('les cases sures sont les memes', () {
      expect((grille['safeZones'] as List).toSet(), safeZones);
    });
  });

  group('Etat envoye a la scene', () {
    GameState partie() => GameState.initial(GameMode.vsComputer,
        [PlayerColor.red, PlayerColor.blue, PlayerColor.green]);

    test('porte les positions de chaque pion, par couleur', () {
      final etat = partie();
      etat.players[1].pawns[2].position = 17;
      final json = boardSnapshot(etat);
      final joueurs = json['players'] as List;
      expect(joueurs, hasLength(3));
      expect(joueurs[1], {
        'color': 'blue',
        'pawns': [-1, -1, 17, -1],
      });
      expect(json.containsKey('move'), isFalse);
    });

    test('ne montre des pions jouables que quand il faut choisir', () {
      final etat = partie()
        ..movablePawnIndices = [0, 2]
        ..phase = GamePhase.rolling;
      expect(boardSnapshot(etat)['movable'], isEmpty);
      etat.phase = GamePhase.choosingPawn;
      expect(boardSnapshot(etat)['movable'], [0, 2]);
      expect(boardSnapshot(etat)['phase'], 'choosingPawn');
    });

    test('decrit le dernier coup et la derniere capture avec leur version', () {
      final json = boardSnapshot(
        partie(),
        lastMove: const LastMoveInfo(
          playerIdx: 0,
          pawnIdx: 1,
          fromPosition: 3,
          toPosition: 6,
          color: PlayerColor.red,
          path: [4, 5, 6],
        ),
        moveVersion: 7,
        lastCapture: const CaptureEffectInfo(
          captureCellPosition: 6,
          capturedPawns: [
            CapturedPawnInfo(
              playerIdx: 2,
              pawnIdx: 0,
              fromPosition: 6,
              toPosition: -1,
              color: PlayerColor.green,
            ),
          ],
        ),
        captureVersion: 2,
      );
      expect(json['move'], {
        'version': 7,
        'player': 0,
        'pawn': 1,
        'fromPos': 3,
        'path': [4, 5, 6],
      });
      expect(json['capture'], {
        'version': 2,
        'cellPos': 6,
        'pawns': [
          {'player': 2, 'pawn': 0, 'fromPos': 6},
        ],
      });
      // Tout doit passer tel quel dans la WebView.
      expect(() => jsonEncode(json), returnsNormally);
    });
  });
}
