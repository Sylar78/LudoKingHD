// Chaque couleur a son animal, et deux couleurs n'en partagent jamais un :
// c'est ce qui permet de reconnaitre un pion a la silhouette, sans compter
// sur la couleur seule.

import 'package:flutter_test/flutter_test.dart';

import 'package:ludo_king_hd/models/player_color.dart';
import 'package:ludo_king_hd/widgets/pawn_figures.dart';

void main() {
  test('chaque couleur a un animal, et un seul', () {
    final parCouleur = {
      for (final couleur in PlayerColor.values) couleur: speciesFor(couleur),
    };
    expect(parCouleur.length, PlayerColor.values.length);
    expect(parCouleur.values.toSet().length, PlayerColor.values.length,
        reason: 'deux couleurs partagent le meme animal');
  });

  test('tous les animaux sont nommes', () {
    for (final espece in AnimalSpecies.values) {
      expect(speciesLabel(espece), isNotEmpty);
    }
  });

  test('chaque animal est attribue a une couleur', () {
    final utilises = PlayerColor.values.map(speciesFor).toSet();
    expect(utilises, AnimalSpecies.values.toSet());
  });
}
