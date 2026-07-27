Créer une application mobile de jeu façon Ludo King.

Fonctionnalités attendues:


Ludo King est la version numérique du célèbre jeu Petits Chevaux (Ludo). Le but est simple : être le premier joueur à ramener ses 4 pions au centre du plateau ("Home"). Le jeu est toutefois plus stratégique qu'il n'y paraît.

1. Le plateau

Le plateau est composé de :

4 couleurs (Rouge, Bleu, Vert, Jaune)
Chaque joueur possède 4 pions
Une base (l'endroit où commencent les pions)
Une piste extérieure sur laquelle les pions tournent
Une ligne finale de la couleur du joueur
Le centre, qui représente l'arrivée.

Chaque joueur effectue exactement un tour complet du plateau avant de rejoindre sa ligne d'arrivée.

2. Objectif

Le gagnant est le premier qui réussit à :

sortir ses 4 pions,
effectuer un tour complet,
faire entrer les 4 pions au centre.
3. Début de partie

Au départ, les 4 pions sont enfermés dans la base.

Pour faire sortir un pion :

🎲 il faut obtenir un 6.

Lorsque tu fais un 6 :

tu peux sortir un nouveau pion,
ou avancer un pion déjà sur le plateau.

Ensuite tu relances immédiatement le dé.

Exemple :

Tu fais :

6

Tu sors un pion.

Tu relances.

Tu fais :

4

Ton pion avance de 4 cases.

4. Déplacement

Chaque lancer correspond exactement au nombre de cases parcourues.

Exemple :

Tu obtiens :

5

Ton pion avance de 5 cases.

Impossible de faire moins ou plus.

5. Plusieurs pions

Tu peux avoir :

1 pion
2 pions
3 pions
ou les 4 pions sur le plateau.

À chaque lancer, tu choisis quel pion déplacer.

C'est là que la stratégie commence.

6. Capturer un adversaire

Si ton pion arrive exactement sur la case occupée par un pion adverse :

➡️ le pion adverse retourne immédiatement dans sa base.

Il devra refaire un 6 pour ressortir.

En récompense :

tu rejoues immédiatement.

7. Les cases protégées

Certaines cases sont marquées par une étoile.

Ce sont des Safe Zones.

Sur ces cases :

impossible de capturer
impossible d'être capturé.

Si un joueur est dessus, tu peux t'arrêter sur cette case sans le renvoyer.

8. Les 6

Lorsque tu fais un 6 :

Tu obtiens :

un déplacement de 6
un lancer supplémentaire

Tu peux donc parfois jouer plusieurs fois d'affilée.

9. Les trois 6 consécutifs

Si tu fais :

6 → 6 → 6

Le troisième 6 est annulé :

ton tour prend fin,
tu ne bénéficies pas du troisième déplacement.
10. Entrer dans la ligne finale

Après avoir fait un tour complet, ton pion entre dans la ligne de sa couleur.

À partir de là :

plus personne ne peut le capturer,
seul toi peux avancer dessus.
11. Entrer au centre

Pour atteindre le centre :

Il faut le nombre exact.

Exemple :

Il reste :

3 cases.

Tu fais :

5

Tu ne peux pas avancer.

Le pion attendra le prochain tour.

12. Empiler deux pions (blocage)

Dans certaines variantes de Ludo King, deux pions d'un même joueur peuvent être sur la même case.

Ils forment alors un bloc.

Ce bloc :

est généralement impossible à capturer,
bloque souvent le passage des adversaires selon le mode de jeu.

Toutes les variantes n'activent pas cette règle.

13. Quand rejoue-t-on ?

Tu rejoues lorsque :

tu fais un 6 ;
tu captures un pion adverse ;
dans les règles classiques de Ludo King, lorsqu'un pion atteint le centre.
14. Comment gagner ?

Le premier joueur qui place :

✅ pion 1

✅ pion 2

✅ pion 3

✅ pion 4

au centre remporte la partie.

Les autres continuent souvent pour déterminer les places suivantes.

15. Les différents modes de jeu

Ludo King propose notamment :

Vs Computer : contre l'ordinateur.
Local Multiplayer : plusieurs joueurs sur le même appareil.
Online Multiplayer : contre des joueurs du monde entier.
Private Room : avec des amis.
Team Mode : 2 contre 2.
Quick Mode : parties plus rapides avec des règles adaptées.


- Un parcours d'apprentissage visuel, découpé en plusieurs leçons successives (une dizaine de leçon suffit), présenté sous forme de chemin ou de liste
progressive où l'utilisateur doit terminer une leçon pour débloque la suivante
- Chaque leçon contient une série de 5 à 8



Design attendu : 
- Une interface colorée, ludique et motivante, dans un esprit gamifié. Reprends le style de l'application Ludo King
mais avec un rendu graphique plus beau.

Contraintes techniques:
L'app doit être fonctionelle de bout en bout sans nécéssité de compte utilisteur ni de backend externe - les données peuvent stockées localement.

Utilise les techno ci-dessous (pas obligatoirement si tu trouves mieux)

Frontend mobile
Dart
Flutter (UI cross-platform Android/iOS/Web/Desktop)
Gestion d’état avec Provider
Animations/UI avec Lottie, Flutter SVG, Shimmer, Flutter Animate
Android
Kotlin (côté natif Android)
Gradle (scripts de build Android)
Android SDK (compile/target récents, multidex, billing Play)
iOS
Swift/Objective-C via l’écosystème Flutter (plugins natifs)
CocoaPods (gestion des dépendances iOS, Podfile en Ruby)
Backend
JavaScript (Node.js)
Express (API REST)
Redis + Bull (file de jobs / queue)
LibreOffice (conversion DOC vers PDF)
Sharp, pdf-lib, mammoth, multer, puppeteer-core (traitements fichiers/PDF/images)
Base de données et cloud
Supabase
SQL / PostgreSQL (schéma, RLS, triggers, vues)
Stockage Supabase (fichiers convertis)
DevOps / exécution
Docker Compose (orchestration API + workers + Redis)




Construis l'application complète en une seule fois.