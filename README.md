# Ludo King HD

Jeu de ludo en Flutter : parties contre l'ordinateur, plateau dessiné au
`CustomPainter`, et un parcours d'apprentissage des règles.

## Démarrer

```
flutter pub get
flutter run
```

## Vérifier avant de pousser

```
flutter analyze --no-fatal-infos
flutter test
```

Les deux sont rejoués par les workflows de publication, qui refusent de
déposer quoi que ce soit s'ils échouent.

## Publier

Voir [docs/publication.md](docs/publication.md) pour les valeurs propres à ce
dépôt, et [docs/publier-une-app-flutter.md](docs/publier-une-app-flutter.md)
pour la marche à suivre complète sur Google Play et l'App Store.

## Organisation

- `lib/models/` — pions, joueurs, couleurs, état de partie
- `lib/utils/game_engine.dart` — les règles : sortie sur un 6, compte exact
  pour le centre, prises
- `lib/utils/board_layout.dart` — position d'une case sur la grille 15×15
- `lib/widgets/` — plateau, dé, panneaux de joueur
- `lib/screens/` — menu, partie, apprentissage, réglages
- `test/` — tests des règles, sans widget
