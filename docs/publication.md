# Publier LudoKingHD

Ce fichier ne donne que ce qui est propre à ce dépôt. La marche à suivre
complète, avec les pièges déjà rencontrés et vérifiés, est dans
[publier-une-app-flutter.md](publier-une-app-flutter.md).

## Les valeurs figées

| Quoi | Valeur |
| --- | --- |
| Identifiant de bundle iOS | `com.ludokinghd.app` |
| Identifiant d'application Android | `com.ludokinghd.app` |
| Nom sous l'icône | `Ludo King HD` |
| Version minimale d'iOS | `15.0` |
| Version de Flutter en CI | `3.24.5` |

Les deux identifiants sont volontairement les mêmes : c'est ce qui permet de
donner le même identifiant de produit aux abonnements des deux stores le jour
où il y en aura. Ils ne pourront plus changer une fois l'app publiée.

Le paquet Kotlin du code Android reste `com.ludokinghd.ludo_king_hd` : c'est
le `namespace` de Gradle, il n'a rien à voir avec les stores, et le renommer
n'apporterait rien.

La version minimale d'iOS est écrite à trois endroits, qui doivent rester
d'accord. Le workflow les compare avant de construire :

- `ios/Flutter/AppFrameworkInfo.plist`, clé `MinimumOSVersion` ;
- `ios/Podfile`, ligne `platform :ios` ;
- `ios/Runner.xcodeproj/project.pbxproj`, `IPHONEOS_DEPLOYMENT_TARGET`.

## Les workflows

- `.github/workflows/publication-play.yml` — construit le bundle signé et le
  dépose sur une piste de la Play Console. Étiquette `v1.0.1`, ou « Run
  workflow » avec le choix de la piste. Une publication en production part en
  brouillon.
- `.github/workflows/publication-testflight.yml` — construit l'archive iOS
  signée et la dépose sur TestFlight. Étiquette `ios-v1.0.1`, ou « Run
  workflow ». La soumission à l'App Store reste un geste humain.

Les deux refusent de déposer quoi que ce soit si `flutter analyze` ou
`flutter test` échoue.

## Les secrets à créer

Aucun n'est encore en place ; tant qu'ils manquent, les workflows s'arrêtent
à leur première étape avec la liste de ce qui manque.

Android, cinq secrets : `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,
`PLAY_SERVICE_ACCOUNT_JSON`.

iOS, huit secrets : `APPLE_TEAM_ID`, `IOS_DIST_CERT_P12_BASE64`,
`IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`,
`IOS_PROVISIONING_PROFILE_NAME`, `APP_STORE_CONNECT_KEY_ID`,
`APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_PRIVATE_KEY`.

D'où vient chacun : section 4 du guide.

## Ce qui reste ouvert

- **Le nom en boutique.** « Ludo King » est le nom d'un jeu existant, déposé
  par un autre éditeur. Une fiche publiée sous « Ludo King HD » a de bonnes
  chances d'être refusée, sur l'App Store comme sur Play, ou retirée sur
  réclamation. Le nom de la fiche se choisit au moment de créer l'app chez
  Apple et chez Google, et il se change ensuite ; l'identifiant de bundle,
  lui, ne se change plus. C'est pour ça qu'il ne contient pas le nom.
- **La monétisation.** Rien n'est en place : ni publicités, ni abonnements.
  Les sections 8 et 9 du guide décrivent ce que ça demande le jour où ce
  sera décidé.
- **Les ressources.** `pubspec.yaml` ne déclare plus de dossier `assets/` :
  les trois qui y figuraient n'existaient pas et faisaient échouer l'analyse.
  À redéclarer quand il y aura des fichiers à embarquer.
