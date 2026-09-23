import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Le fond commun aux écrans : dégradé de nuit, halos aux quatre couleurs du
/// jeu, et une trame de losanges très discrète qui rappelle le plateau.
///
/// Tout est peint, donc rien à embarquer : le dépôt ne porte aucune image.
class AppBackground extends StatelessWidget {
  final Widget child;

  /// Les halos de couleur, à couper sur les écrans denses comme la partie.
  final bool showGlows;

  const AppBackground({super.key, required this.child, this.showGlows = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.night),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackdropPainter(showGlows: showGlows),
              isComplex: true,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final bool showGlows;

  const _BackdropPainter({required this.showGlows});

  // Les quatre couleurs du plateau, posées dans les coins correspondants.
  static const _glows = <(Alignment, Color)>[
    (Alignment.topLeft, Color(0xFFE53935)),
    (Alignment.topRight, Color(0xFF1E88E5)),
    (Alignment.bottomLeft, Color(0xFFFDD835)),
    (Alignment.bottomRight, Color(0xFF43A047)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (showGlows) {
      for (final (alignment, color) in _glows) {
        final centre = alignment.withinRect(Offset.zero & size);
        final rayon = size.shortestSide * 0.62;
        canvas.drawCircle(
          centre,
          rayon,
          Paint()
            ..shader = RadialGradient(
              colors: [color.withOpacity(0.20), color.withOpacity(0)],
            ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
        );
      }
    }

    // Trame de losanges, dans le sens du plateau.
    final trait = Paint()
      ..color = Colors.white.withOpacity(0.030)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const pas = 46.0;
    final diagonale = size.width + size.height;
    for (var d = -size.height; d < diagonale; d += pas) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), trait);
      canvas.drawLine(
          Offset(d, size.height), Offset(d + size.height, 0), trait);
    }

    // Quelques points lumineux, posés sur une suite déterministe : le fond ne
    // doit pas changer d'une reconstruction a l'autre.
    final etoile = Paint()..color = Colors.white.withOpacity(0.16);
    for (var i = 0; i < 28; i++) {
      final x = (math.sin(i * 12.9898) * 43758.5453).abs() % 1 * size.width;
      final y = (math.sin(i * 78.233) * 43758.5453).abs() % 1 * size.height;
      canvas.drawCircle(Offset(x, y), 1.0 + (i % 3) * 0.4, etoile);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.showGlows != showGlows;
}
