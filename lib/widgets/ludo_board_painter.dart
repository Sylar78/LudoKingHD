import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/board_constants.dart';
import '../models/game_state.dart';
import '../models/move_info.dart';
import '../models/pawn.dart';
import '../models/player.dart';
import '../models/player_color.dart';
import '../utils/board_layout.dart';

class LudoBoardPainter extends CustomPainter {
  final GameState? state;
  final List<int> highlightedPawnIndices;
  final LastMoveInfo? activeMove;
  final double animProgress;

  LudoBoardPainter({
    this.state,
    required this.highlightedPawnIndices,
    this.activeMove,
    this.animProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 15;

    _drawGrid(canvas, size, cellSize);
    _drawBases(canvas, cellSize);
    _drawHomeColumns(canvas, cellSize);
    _drawCentre(canvas, size, cellSize);
    _drawSafeZoneStars(canvas, cellSize);
    if (state != null) {
      _drawPawns(canvas, cellSize);
    }
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize) {
    // Clip grid to the cross shape – exclude the 4 corner base zones (6×6 each)
    canvas.save();
    final clip = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(0, 0, 6 * cellSize, 6 * cellSize))
      ..addRect(Rect.fromLTWH(9 * cellSize, 0, 6 * cellSize, 6 * cellSize))
      ..addRect(Rect.fromLTWH(9 * cellSize, 9 * cellSize, 6 * cellSize, 6 * cellSize))
      ..addRect(Rect.fromLTWH(0, 9 * cellSize, 6 * cellSize, 6 * cellSize));
    clip.fillType = PathFillType.evenOdd;
    canvas.clipPath(clip);

    final gridPaint = Paint()
      ..color = Colors.grey.shade400.withOpacity(0.45)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(
          Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(
          Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }
    canvas.restore();
  }

  void _drawBases(Canvas canvas, double cellSize) {
    final colors = {
      PlayerColor.red: const Color(0xFFE53935),
      PlayerColor.blue: const Color(0xFF1E88E5),
      PlayerColor.green: const Color(0xFF43A047),
      PlayerColor.yellow: const Color(0xFFFDD835),
    };
    final regions = {
      PlayerColor.red: const Rect.fromLTWH(0, 0, 6, 6),
      PlayerColor.blue: const Rect.fromLTWH(9, 0, 6, 6),
      PlayerColor.green: const Rect.fromLTWH(9, 9, 6, 6),
      PlayerColor.yellow: const Rect.fromLTWH(0, 9, 6, 6),
    };

    for (final entry in regions.entries) {
      final r = entry.value;
      final c = colors[entry.key]!;

      // Background – solid dark-tinted colour
      final bgPaint = Paint()..color = Color.lerp(c, Colors.black, 0.30)!;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left * cellSize, r.top * cellSize,
                  r.width * cellSize, r.height * cellSize),
              const Radius.circular(10)),
          bgPaint);

      // Border
      final borderPaint = Paint()
        ..color = c
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left * cellSize + 2, r.top * cellSize + 2,
              r.width * cellSize - 4, r.height * cellSize - 4),
          const Radius.circular(8));
      canvas.drawRRect(rr, borderPaint);

      // Inner circle
      final innerCirclePaint = Paint()..color = c.withOpacity(0.45);
      final centerX = (r.left + r.width / 2) * cellSize;
      final centerY = (r.top + r.height / 2) * cellSize;
      canvas.drawCircle(
          Offset(centerX, centerY), r.width * cellSize * 0.40, innerCirclePaint);
    }
  }

  void _drawHomeColumns(Canvas canvas, double cellSize) {
    final colors = {
      PlayerColor.red: const Color(0xFFE53935),
      PlayerColor.blue: const Color(0xFF1E88E5),
      PlayerColor.green: const Color(0xFF43A047),
      PlayerColor.yellow: const Color(0xFFFDD835),
    };

    for (final entry in BoardLayout.homeColumns.entries) {
      final color = colors[entry.key]!;
      final paint = Paint()..color = color.withOpacity(0.45);
      for (int i = 0; i < entry.value.length - 1; i++) {
        final cell = entry.value[i];
        canvas.drawRect(
            Rect.fromLTWH(cell.$2 * cellSize + 1, cell.$1 * cellSize + 1,
                cellSize - 2, cellSize - 2),
            paint);
      }
    }
  }

  void _drawCentre(Canvas canvas, Size size, double cellSize) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cellSize * 1.5;

    // Draw a coloured triangle for each quadrant
    final colours = [
      (const Color(0xFFE53935), [Offset(cx, cy), Offset(cx - r, cy - r), Offset(cx + r, cy - r)]), // top=red
      (const Color(0xFF1E88E5), [Offset(cx, cy), Offset(cx + r, cy - r), Offset(cx + r, cy + r)]), // right=blue
      (const Color(0xFF43A047), [Offset(cx, cy), Offset(cx + r, cy + r), Offset(cx - r, cy + r)]), // bottom=green
      (const Color(0xFFFDD835), [Offset(cx, cy), Offset(cx - r, cy + r), Offset(cx - r, cy - r)]), // left=yellow
    ];

    for (final tri in colours) {
      final path = Path()
        ..moveTo(tri.$2[0].dx, tri.$2[0].dy)
        ..lineTo(tri.$2[1].dx, tri.$2[1].dy)
        ..lineTo(tri.$2[2].dx, tri.$2[2].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = tri.$1);
    }

    // No white circle – coloured triangles form the home design
  }

  void _drawSafeZoneStars(Canvas canvas, double cellSize) {
    for (final idx in safeZones) {
      if (idx < 0 || idx >= BoardLayout.outerPath.length) continue;
      final cell = BoardLayout.outerPath[idx];
      final left = cell.$2 * cellSize;
      final top  = cell.$1 * cellSize;
      final cx   = left + cellSize / 2;
      final cy   = top  + cellSize / 2;

      // Gold background
      canvas.drawRect(
        Rect.fromLTWH(left + 0.5, top + 0.5, cellSize - 1, cellSize - 1),
        Paint()..color = const Color(0xFFFFF8DC),
      );

      // 5-pointed star
      final star = _buildStarPath(cx, cy, cellSize * 0.38, cellSize * 0.16);
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFC107));
      canvas.drawPath(
        star,
        Paint()
          ..color = const Color(0xFFFF8F00)
          ..strokeWidth = 0.7
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _buildStarPath(double cx, double cy, double outerR, double innerR) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawPawns(Canvas canvas, double cellSize) {
    final s = state!;
    for (int pi = 0; pi < s.players.length; pi++) {
      final player = s.players[pi];
      for (int i = 0; i < player.pawns.length; i++) {
        // Skip the pawn currently being animated (drawn separately below)
        if (activeMove != null &&
            pi == activeMove!.playerIdx &&
            i == activeMove!.pawnIdx) continue;
        _drawSinglePawn(canvas, cellSize, player.pawns[i], pi, i, s);
      }
    }
    // Animated pawn drawn last so it renders on top
    if (activeMove != null) _drawAnimatedPawn(canvas, cellSize, s);
  }

  // Interpolated hop animation – advances one cell at a time
  void _drawAnimatedPawn(Canvas canvas, double cellSize, GameState s) {
    final move  = activeMove!;
    final pawn  = s.players[move.playerIdx].pawns[move.pawnIdx];
    final path  = move.path;

    if (path.isEmpty) return;

    final numSteps = path.length;
    final totalT   = animProgress.clamp(0.0, 1.0);
    final scaledT  = totalT * numSteps;
    final stepIdx  = scaledT.floor().clamp(0, numSteps - 1);
    final stepT    = (scaledT - stepIdx).clamp(0.0, 1.0);

    final fromPos = stepIdx == 0 ? move.fromPosition : path[stepIdx - 1];
    final toPos   = path[stepIdx];

    final from = _resolveOffset(fromPos, move.color, move.pawnIdx, cellSize);
    final to   = _resolveOffset(toPos,   move.color, move.pawnIdx, cellSize);

    final t   = Curves.easeInOut.transform(stepT);
    final cx  = from.$1 + (to.$1 - from.$1) * t;
    final cy  = from.$2 + (to.$2 - from.$2) * t;
    final hop = cellSize * 0.85 * math.sin(math.pi * t); // hop height per step

    _drawChessPawn(
        canvas, cx, cy - hop + cellSize * 0.33, cellSize, pawn.color.color, false);
  }

  (double, double) _resolveOffset(
      int position, PlayerColor color, int pawnIdx, double cellSize) {
    if (position == -1) {
      return BoardLayout.basePositionOffset(color, pawnIdx, cellSize);
    }
    return BoardLayout.positionToOffset(position, color, cellSize);
  }

  void _drawSinglePawn(Canvas canvas, double cellSize, Pawn pawn, int playerIdx,
      int pawnIdx, GameState s) {
    double cx, cy;

    if (pawn.isInBase) {
      final off =
          BoardLayout.basePositionOffset(pawn.color, pawnIdx, cellSize);
      cx = off.$1;
      cy = off.$2;
    } else {
      final off =
          BoardLayout.positionToOffset(pawn.position, pawn.color, cellSize);
      cx = off.$1;
      cy = off.$2;
    }

    final isCurrentPlayer = playerIdx == s.currentPlayerIndex;
    final isMovable = isCurrentPlayer &&
        highlightedPawnIndices.contains(pawnIdx) &&
        s.phase == GamePhase.choosingPawn;

    // Vertical centre of the cell → pawn base sits slightly below centre
    final bottomY = cy + cellSize * 0.32;
    _drawChessPawn(canvas, cx, bottomY, cellSize, pawn.color.color, isMovable);
  }

  // ── 3D Isometric Chess Pawn with collar ─────────────────────────────────
  void _drawChessPawn(Canvas canvas, double cx, double baseY, double cellSize,
      Color color, bool isMovable) {
    final cLight  = Color.lerp(color, Colors.white, 0.58)!;
    final cLight2 = Color.lerp(color, Colors.white, 0.28)!;
    final cDark   = Color.lerp(color, Colors.black, 0.52)!;

    final baseW   = cellSize * 0.52;
    final baseH   = cellSize * 0.12;
    final collarW = cellSize * 0.22;
    final collarH = cellSize * 0.065;
    final headR   = cellSize * 0.27;

    // Y positions (bottom → top)
    final discTopY      = baseY;
    final bodyTopY      = discTopY - baseH * 0.5 - cellSize * 0.18;
    final collarBottomY = bodyTopY - cellSize * 0.01;
    final collarTopY    = collarBottomY - collarH;
    final headY         = collarTopY - headR * 0.95;

    // 1. Drop shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 2.5, discTopY + 5),
          width: baseW * 1.9,
          height: baseH * 1.6),
      Paint()
        ..color = Colors.black.withOpacity(0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 2. Base disc – dark bottom rim
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, discTopY + baseH * 0.38),
          width: baseW,
          height: baseH * 0.65),
      Paint()..color = cDark,
    );

    // 3. Base disc – top surface
    final baseRect = Rect.fromCenter(
        center: Offset(cx, discTopY), width: baseW, height: baseH * 0.65);
    canvas.drawOval(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          colors: [cLight, cLight2, cDark],
          stops: const [0.0, 0.45, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(baseRect),
    );

    // 4. Body (trapezoid: wide at base, narrows to collar width)
    final bodyPath = Path()
      ..moveTo(cx - baseW * 0.42, discTopY)
      ..lineTo(cx - collarW / 2 - 2, collarBottomY)
      ..lineTo(cx + collarW / 2 + 2, collarBottomY)
      ..lineTo(cx + baseW * 0.42, discTopY)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [cLight, cLight2, cDark],
          stops: const [0.0, 0.38, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(
            cx - baseW / 2, collarBottomY, baseW, discTopY - collarBottomY)),
    );

    // 5. Collar ring – dark bottom rim
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, collarBottomY + collarH * 0.38),
          width: collarW,
          height: collarH * 0.65),
      Paint()..color = cDark,
    );

    // 6. Collar ring – top surface
    final collarRect = Rect.fromCenter(
        center: Offset(cx, collarBottomY), width: collarW, height: collarH * 0.65);
    canvas.drawOval(
      collarRect,
      Paint()
        ..shader = LinearGradient(
          colors: [cLight, cLight2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(collarRect),
    );

    // 7. Head sphere with radial gradient
    final headRect = Rect.fromCircle(center: Offset(cx, headY), radius: headR);
    canvas.drawCircle(
      Offset(cx, headY),
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.40, -0.42),
          radius: 1.0,
          colors: [cLight, color, cDark],
          stops: const [0.0, 0.44, 1.0],
        ).createShader(headRect),
    );

    // 8a. Primary specular highlight
    canvas.drawCircle(
      Offset(cx - headR * 0.38, headY - headR * 0.38),
      headR * 0.31,
      Paint()..color = Colors.white.withOpacity(0.75),
    );
    // 8b. Secondary specular dot
    canvas.drawCircle(
      Offset(cx - headR * 0.17, headY - headR * 0.60),
      headR * 0.13,
      Paint()..color = Colors.white.withOpacity(0.52),
    );

    // 9. Movable glow rings
    if (isMovable) {
      canvas.drawCircle(
        Offset(cx, headY),
        headR + 6,
        Paint()
          ..color = Colors.amber
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
        Offset(cx, headY),
        headR + 10,
        Paint()
          ..color = Colors.white.withOpacity(0.55)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(LudoBoardPainter oldDelegate) => true;
}
