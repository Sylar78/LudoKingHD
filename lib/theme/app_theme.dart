import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Les couleurs, les polices et les décorations partagées par tous les écrans.
///
/// Avant, chaque écran écrivait ses propres `Color(0xFF...)` : le menu, les
/// dialogues et la partie n'avaient ni le même violet ni le même or, et les
/// dialogues du système (« Recommencer ? ») restaient en clair sur une app
/// sombre. Tout passe désormais par ici.
class AppColors {
  // Fond : du violet nuit vers le noir, du haut vers le bas.
  static const Color nightTop = Color(0xFF2A1A58);
  static const Color nightMid = Color(0xFF1B103E);
  static const Color nightDeep = Color(0xFF120A2C);

  // Surfaces posées sur le fond.
  static const Color surface = Color(0xFF241757);
  static const Color surfaceLow = Color(0xFF181040);

  // L'or : la couleur d'accent du jeu, celle des cadres et des titres.
  static const Color gold = Color(0xFFFFC107);
  static const Color goldLight = Color(0xFFFFD54F);

  // Le bleu des cadres « arcade ».
  static const Color frameTop = Color(0xFF0A3D93);
  static const Color frameBottom = Color(0xFF134CAD);
  static const Color buttonTop = Color(0xFF2C93FF);
  static const Color buttonBottom = Color(0xFF1456B4);

  static const Color violet = Color(0xFF7C4DFF);
  static const Color live = Color(0xFF00E676);

  /// Le fond commun à tous les écrans.
  static const LinearGradient night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [nightTop, nightMid, nightDeep],
    stops: [0.0, 0.55, 1.0],
  );
}

class AppText {
  /// La police d'affichage du jeu, en un seul endroit.
  ///
  /// `google_fonts` la télécharge au premier lancement : sans réseau, Flutter
  /// retombe sur la police système et la mise en page bouge un peu. Le jour où
  /// le `.ttf` sera versionné dans `assets/fonts/`, c'est cette méthode, et
  /// elle seule, qui changera.
  static TextStyle display({
    required double size,
    Color color = Colors.white,
    double letterSpacing = 1.0,
  }) =>
      GoogleFonts.luckiestGuy(
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(2, 2)),
          Shadow(color: Colors.black38, offset: Offset(-1, 1)),
        ],
      );

  static const TextStyle body = TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1.35,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    height: 1.35,
  );
}

/// Le liseré doré des cadres et des boutons du jeu.
BoxDecoration goldFrame({
  required Gradient gradient,
  double radius = 18,
  double borderWidth = 3,
  double glow = 12,
}) =>
    BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.gold, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withOpacity(0.45),
          blurRadius: glow,
          spreadRadius: 1,
        ),
      ],
    );

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.nightDeep,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    // Sans ça, « Recommencer ? » s'ouvrait en blanc sur fond noir.
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.gold.withOpacity(0.5), width: 1.5),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: AppText.bodyMuted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white70),
    ),
  );
}
