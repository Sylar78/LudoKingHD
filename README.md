# Ludo King HD

Jeu de ludo en Flutter : parties contre l'ordinateur, plateau en 3D (Three.js)
sur mobile avec repli au `CustomPainter`, et un parcours d'apprentissage des règles.

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

## Le plateau 3D

Sur Android et iOS, le plateau est une scène Three.js (bois verni, cases en
céramique, figurines d'animaux, ombres portées) affichée dans une WebView.
Ses sources sont dans `board3d/` ; l'app embarque le fichier compilé
`assets/board3d/index.html`, qu'il faut regénérer après toute modification :

```
cd board3d
npm install
npm run build
```

La logique du jeu reste en Dart : `lib/widgets/board3d/` envoie l'état de la
partie à la page et joue le pion qu'elle renvoie. Sur le web, le bureau, ou si
WebGL manque, le plateau 2D (`LudoBoardWidget`) prend le relais.
