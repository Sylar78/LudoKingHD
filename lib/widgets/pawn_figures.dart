import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player_color.dart';

/// Les pions, dessinés en figurines d'animaux.
///
/// Ce sont des figurines peintes, pas des modèles 3D chargés : le relief vient
/// des dégradés, de l'ombre portée et du reflet, comme pour une figurine en
/// résine photographiée de face. Un vrai moteur 3D demanderait un paquet
/// supplémentaire, des fichiers `.glb` dans le dépôt et une surface de rendu
/// par pion ; à seize pions sur un plateau de téléphone, le jeu y perdrait
/// plus qu'il n'y gagnerait.
///
/// Chaque couleur a son animal, choisi pour que la silhouette suffise à le
/// reconnaître à la taille d'une case.
enum AnimalSpecies {
  /// Rouge : oreilles pointues, museau clair.
  renard,

  /// Bleu : aigrettes, grand disque facial, bec court.
  hibou,

  /// Vert : yeux posés sur le dessus du crâne, large sourire.
  grenouille,

  /// Jaune : huppe, bec triangulaire, petite aile.
  poussin,
}

AnimalSpecies speciesFor(PlayerColor color) => switch (color) {
      PlayerColor.red => AnimalSpecies.renard,
      PlayerColor.blue => AnimalSpecies.hibou,
      PlayerColor.green => AnimalSpecies.grenouille,
      PlayerColor.yellow => AnimalSpecies.poussin,
    };

/// Le nom de l'animal, pour les écrans qui le nomment.
String speciesLabel(AnimalSpecies species) => switch (species) {
      AnimalSpecies.renard => 'Renard',
      AnimalSpecies.hibou => 'Hibou',
      AnimalSpecies.grenouille => 'Grenouille',
      AnimalSpecies.poussin => 'Poussin',
    };

/// Dessine une figurine posée sur [baseY], centrée en [cx].
///
/// [scale] vaut 1 pour un pion de plateau ; les aperçus des écrans peuvent
/// demander plus grand.
void paintAnimalPawn(
  Canvas canvas, {
  required double cx,
  required double baseY,
  required double cellSize,
  required PlayerColor color,
  bool isMovable = false,
  double scale = 1.0,
}) {
  final species = speciesFor(color);
  final teinte = color.color;

  final r = cellSize * 0.33 * 1.5 * scale;
  final centerY = baseY - r * 1.02;

  final clair = Color.lerp(teinte, Colors.white, 0.52)!;
  final sombre = Color.lerp(teinte, Colors.black, 0.46)!;
  final tresSombre = Color.lerp(teinte, Colors.black, 0.68)!;

  // ── L'ombre portée : ce qui pose la figurine sur la case ─────────────────
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx + r * 0.16, baseY + r * 0.16),
      width: r * 1.7,
      height: r * 0.5,
    ),
    Paint()
      ..color = Colors.black.withOpacity(0.40)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.30),
  );

  final corps = Rect.fromCenter(
    center: Offset(cx, centerY),
    width: r * 1.76,
    height: r * 2.02,
  );

  // ── Ce qui passe derrière le corps ───────────────────────────────────────
  _paintBehind(canvas, species, corps, r, teinte, sombre, tresSombre);

  // ── Le corps ─────────────────────────────────────────────────────────────
  final formeCorps = Path()..addOval(corps);
  canvas.drawPath(
    formeCorps,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [clair, teinte, sombre],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(corps),
  );

  // Un assombrissement au ras du sol : sans lui la figurine flotte.
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx, centerY + r * 0.72),
      width: r * 1.64,
      height: r * 0.86,
    ),
    Paint()
      ..shader = RadialGradient(
        colors: [tresSombre.withOpacity(0.55), tresSombre.withOpacity(0)],
      ).createShader(Rect.fromCenter(
        center: Offset(cx, centerY + r * 0.72),
        width: r * 1.64,
        height: r * 0.86,
      )),
  );

  // ── Ce qui passe devant : ventre, museau, yeux, bec ──────────────────────
  _paintFront(canvas, species, corps, r, teinte, clair, sombre);

  // ── La lumière : un liseré en haut à gauche, puis un reflet franc ────────
  canvas.save();
  canvas.clipPath(formeCorps);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx - r * 0.30, centerY - r * 0.62),
      width: r * 1.10,
      height: r * 0.72,
    ),
    Paint()
      ..color = Colors.white.withOpacity(0.24)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.22),
  );
  canvas.restore();

  canvas.drawPath(
    formeCorps,
    Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r * 0.07),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(cx - r * 0.40, centerY - r * 0.52),
      width: r * 0.34,
      height: r * 0.24,
    ),
    Paint()..color = Colors.white.withOpacity(0.80),
  );

  // ── L'anneau des pions jouables ──────────────────────────────────────────
  if (isMovable) {
    canvas.drawCircle(
      Offset(cx, centerY),
      r * 1.28,
      Paint()
        ..color = Colors.amber
        ..strokeWidth = math.max(1.6, r * 0.20)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(cx, centerY),
      r * 1.52,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = math.max(1.0, r * 0.12)
        ..style = PaintingStyle.stroke,
    );
  }
}

// ── Les pièces qui passent derrière le corps ───────────────────────────────

void _paintBehind(Canvas canvas, AnimalSpecies species, Rect corps, double r,
    Color teinte, Color sombre, Color tresSombre) {
  final cx = corps.center.dx;
  final cy = corps.center.dy;
  // Ces pieces depassent du corps, souvent sur le fond clair d'une base :
  // teintees plus sombre que le corps et cernees, elles restent lisibles.
  final peau = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [sombre, tresSombre],
    ).createShader(corps);
  final cerne = Paint()
    ..color = tresSombre
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = math.max(0.7, r * 0.07);

  switch (species) {
    case AnimalSpecies.renard:
      // Deux grandes oreilles triangulaires, franchement écartées.
      for (final sens in [-1.0, 1.0]) {
        final base = Offset(cx + sens * r * 0.62, cy - r * 0.62);
        final oreille = Path()
          ..moveTo(base.dx - sens * r * 0.34, base.dy + r * 0.16)
          ..lineTo(base.dx + sens * r * 0.30, base.dy - r * 0.96)
          ..lineTo(base.dx + sens * r * 0.40, base.dy + r * 0.10)
          ..close();
        canvas.drawPath(oreille, peau);
        canvas.drawPath(oreille, cerne);
        // L'interieur de l'oreille, plus clair.
        final dedans = Path()
          ..moveTo(base.dx - sens * r * 0.12, base.dy + r * 0.02)
          ..lineTo(base.dx + sens * r * 0.24, base.dy - r * 0.68)
          ..lineTo(base.dx + sens * r * 0.28, base.dy + r * 0.02)
          ..close();
        canvas.drawPath(dedans, Paint()..color = const Color(0xFFFFE0D2));
      }
    case AnimalSpecies.hibou:
      // Deux aigrettes courtes, rapprochées.
      for (final sens in [-1.0, 1.0]) {
        final aigrette = Path()
          ..moveTo(cx + sens * r * 0.20, cy - r * 0.86)
          ..lineTo(cx + sens * r * 0.58, cy - r * 1.36)
          ..lineTo(cx + sens * r * 0.62, cy - r * 0.72)
          ..close();
        canvas.drawPath(aigrette, peau);
        canvas.drawPath(aigrette, cerne);
      }
    case AnimalSpecies.grenouille:
      // Rien derrière : ses yeux sont posés sur le dessus, donc devant.
      break;
    case AnimalSpecies.poussin:
      // Une huppe de trois plumes.
      for (final (dx, h) in [(-0.34, 0.46), (0.0, 0.70), (0.34, 0.46)]) {
        final plume = Rect.fromCenter(
          center: Offset(cx + r * dx, cy - r * (0.88 + h * 0.5)),
          width: r * 0.32,
          height: r * h,
        );
        canvas.drawOval(plume, peau);
        canvas.drawOval(plume, cerne);
      }
  }
}

// ── Les pièces qui passent devant le corps ─────────────────────────────────

void _paintFront(Canvas canvas, AnimalSpecies species, Rect corps, double r,
    Color teinte, Color clair, Color sombre) {
  final cx = corps.center.dx;
  final cy = corps.center.dy;

  final blanc = Paint()..color = const Color(0xFFFFF8F0);
  final noir = Paint()..color = const Color(0xFF1A1A22);
  final bec = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFC44D), Color(0xFFE88C10)],
    ).createShader(Rect.fromCenter(
      center: Offset(cx, cy + r * 0.24),
      width: r * 0.7,
      height: r * 0.7,
    ));

  switch (species) {
    case AnimalSpecies.renard:
      // Museau clair, puis truffe.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.44),
          width: r * 0.98,
          height: r * 0.80,
        ),
        blanc,
      );
      _oeil(canvas, Offset(cx - r * 0.36, cy - r * 0.12), r * 0.24);
      _oeil(canvas, Offset(cx + r * 0.36, cy - r * 0.12), r * 0.24);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.30),
          width: r * 0.30,
          height: r * 0.22,
        ),
        noir,
      );

    case AnimalSpecies.hibou:
      // Le disque facial, deux cercles clairs qui se recouvrent.
      for (final sens in [-1.0, 1.0]) {
        canvas.drawCircle(
            Offset(cx + sens * r * 0.32, cy - r * 0.10), r * 0.50, blanc);
      }
      _oeil(canvas, Offset(cx - r * 0.32, cy - r * 0.10), r * 0.30);
      _oeil(canvas, Offset(cx + r * 0.32, cy - r * 0.10), r * 0.30);
      final becHibou = Path()
        ..moveTo(cx - r * 0.16, cy + r * 0.26)
        ..lineTo(cx + r * 0.16, cy + r * 0.26)
        ..lineTo(cx, cy + r * 0.62)
        ..close();
      canvas.drawPath(becHibou, bec);

    case AnimalSpecies.grenouille:
      // Les yeux dépassent du crâne : c'est ce qui la rend reconnaissable.
      for (final sens in [-1.0, 1.0]) {
        final centre = Offset(cx + sens * r * 0.46, cy - r * 0.84);
        canvas.drawCircle(
          centre,
          r * 0.40,
          Paint()
            ..shader = RadialGradient(
              colors: [clair, teinte],
            ).createShader(Rect.fromCircle(center: centre, radius: r * 0.40)),
        );
        _oeil(canvas, centre, r * 0.28);
      }
      // Le sourire, d'un bord à l'autre.
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.10),
          width: r * 1.20,
          height: r * 0.96,
        ),
        0.18 * math.pi,
        0.64 * math.pi,
        false,
        Paint()
          ..color = sombre
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(1.0, r * 0.13),
      );
      for (final sens in [-1.0, 1.0]) {
        canvas.drawCircle(
            Offset(cx + sens * r * 0.16, cy - r * 0.12), r * 0.07, noir);
      }

    case AnimalSpecies.poussin:
      _oeil(canvas, Offset(cx - r * 0.32, cy - r * 0.24), r * 0.24);
      _oeil(canvas, Offset(cx + r * 0.32, cy - r * 0.24), r * 0.24);
      final becPoussin = Path()
        ..moveTo(cx - r * 0.24, cy + r * 0.18)
        ..lineTo(cx + r * 0.24, cy + r * 0.18)
        ..lineTo(cx, cy + r * 0.58)
        ..close();
      canvas.drawPath(becPoussin, bec);
      // L'aile, sur le flanc éclairé.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - r * 0.62, cy + r * 0.30),
          width: r * 0.42,
          height: r * 0.74,
        ),
        Paint()..color = clair.withOpacity(0.85),
      );
  }
}

/// Un œil : le blanc, la pupille, et le petit éclat qui le rend vivant.
void _oeil(Canvas canvas, Offset centre, double rayon) {
  canvas.drawCircle(centre, rayon, Paint()..color = const Color(0xFFFFFDF8));
  canvas.drawCircle(
    centre,
    rayon * 0.60,
    Paint()..color = const Color(0xFF17171F),
  );
  canvas.drawCircle(
    Offset(centre.dx - rayon * 0.24, centre.dy - rayon * 0.28),
    rayon * 0.24,
    Paint()..color = Colors.white,
  );
}

/// La même figurine, hors du plateau : cartes de joueurs, choix de couleur.
class AnimalFigure extends StatelessWidget {
  final PlayerColor color;
  final double size;

  const AnimalFigure({super.key, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnimalFigurePainter(color),
        // Les lecteurs d'écran annoncent l'animal, pas un dessin sans nom.
        child: Semantics(
          label: '${speciesLabel(speciesFor(color))} ${color.name}',
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AnimalFigurePainter extends CustomPainter {
  final PlayerColor color;

  const _AnimalFigurePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // La figurine monte d'environ 2,4 rayons au-dessus de sa base, aigrettes
    // comprises : ce facteur la fait tenir entière dans le carré demandé.
    final cote = size.shortestSide;
    paintAnimalPawn(
      canvas,
      cx: size.width / 2,
      baseY: cote * 0.90,
      cellSize: cote * 0.70,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_AnimalFigurePainter oldDelegate) =>
      oldDelegate.color != color;
}
