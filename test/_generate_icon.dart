// Outil ponctuel : dessine l'icône de l'app (plateau stylisé + les quatre
// animaux) et l'enregistre dans assets/icon/app_icon.png. Se lance avec
// `flutter test test/_generate_icon.dart`, puis se supprime : ce n'est pas un
// test, seulement le moyen le plus simple de faire rendre un CustomPainter
// Flutter par le moteur pour produire un PNG.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_king_hd/models/player_color.dart';
import 'package:ludo_king_hd/widgets/pawn_figures.dart';

const _size = 1024.0;

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(_size, _size),
      painter: _IconPainter(),
    );
  }
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fond : le même violet profond que l'écran de jeu, pour que l'icône
    // annonce l'app avant même de l'ouvrir.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1A57), Color(0xFF1A1038), Color(0xFF10092A)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // Le plateau : un losange aux quatre couleurs du jeu, cerné d'or, qui
    // évoque le damier sans tenter de le reproduire à cette taille.
    final board = Rect.fromCenter(
      center: rect.center,
      width: size.width * 0.86,
      height: size.height * 0.86,
    );
    final diamond = Path()
      ..moveTo(board.center.dx, board.top)
      ..lineTo(board.right, board.center.dy)
      ..lineTo(board.center.dx, board.bottom)
      ..lineTo(board.left, board.center.dy)
      ..close();

    canvas.save();
    canvas.clipPath(diamond);
    final quadrants = <(PlayerColor, Alignment)>[
      (PlayerColor.red, Alignment.topLeft),
      (PlayerColor.blue, Alignment.topRight),
      (PlayerColor.green, Alignment.bottomLeft),
      (PlayerColor.yellow, Alignment.bottomRight),
    ];
    for (final (color, align) in quadrants) {
      final quad = Rect.fromCenter(
        center: Offset(
          board.center.dx + align.x * board.width / 4,
          board.center.dy + align.y * board.height / 4,
        ),
        width: board.width / 2,
        height: board.height / 2,
      );
      canvas.drawRect(
        quad,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.lightColor.withOpacity(0.95), color.color],
          ).createShader(quad),
      );
    }
    // Croisée centrale ivoire, comme la case de départ du plateau réel.
    canvas.drawCircle(
      board.center,
      board.width * 0.16,
      Paint()..color = const Color(0xFFFFF8EC),
    );
    canvas.restore();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xFFD9A441)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.022,
    );

    // Les quatre animaux, un par couleur, assis sur leur quart du plateau.
    // Les oreilles et aigrettes montent haut au-dessus du point d'ancrage
    // (baseY) : les rangées sont donc placées bas dans leur moitié, avec une
    // figurine assez petite pour que rien ne sorte du cadre.
    final cellSize = size.width * 0.20;
    final dx = size.width * 0.235;
    final pawns = <(PlayerColor, Offset)>[
      (PlayerColor.red, Offset(rect.center.dx - dx, size.height * 0.365)),
      (PlayerColor.blue, Offset(rect.center.dx + dx, size.height * 0.365)),
      (PlayerColor.green, Offset(rect.center.dx - dx, size.height * 0.775)),
      (PlayerColor.yellow, Offset(rect.center.dx + dx, size.height * 0.775)),
    ];
    for (final (color, center) in pawns) {
      paintAnimalPawn(
        canvas,
        cx: center.dx,
        baseY: center.dy,
        cellSize: cellSize,
        color: color,
        scale: 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => false;
}

void main() {
  testWidgets('génère assets/icon/app_icon.png', (tester) async {
    await tester.pumpWidget(const RepaintBoundary(child: _AppIcon()));
    await tester.pump();

    final element = find.byType(_AppIcon).evaluate().single;
    final boundary =
        element.findRenderObject()!.parent as RenderRepaintBoundary;

    // toImage()/toByteData() font un aller-retour natif réel : dans la zone
    // FakeAsync de flutter_test, leur Future ne se résout jamais sans
    // runAsync, qui bascule temporairement sur la vraie boucle d'événements.
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final file = File('assets/icon/app_icon.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
