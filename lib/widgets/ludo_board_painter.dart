import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/board_constants.dart';
import '../models/game_state.dart';
import '../models/move_info.dart';
import '../models/pawn.dart';
import 'pawn_figures.dart';
import '../models/player_color.dart';
import '../utils/board_layout.dart';

class LudoBoardPainter extends CustomPainter {
  final GameState? state;
  final List<int> highlightedPawnIndices;
  final LastMoveInfo? activeMove;
  final double animProgress;
  final CaptureEffectInfo? activeCapture;
  final CaptureEffectInfo? pendingCapture;
  final double captureProgress;

  LudoBoardPainter({
    this.state,
    required this.highlightedPawnIndices,
    this.activeMove,
    this.animProgress = 0.0,
    this.activeCapture,
    this.pendingCapture,
    this.captureProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSide = math.min(size.width, size.height);
    final dx = (size.width - boardSide) / 2;
    final dy = (size.height - boardSide) / 2;
    final boardSize = Size(boardSide, boardSide);
    final cellSize = boardSide / 15;

    canvas.save();
    canvas.translate(dx, dy);

    _drawBoardBackdrop(canvas, boardSize);
    _drawGrid(canvas, boardSize, cellSize);
    _drawBases(canvas, cellSize);
    _drawHomeColumns(canvas, cellSize);
    _drawEntryArrows(canvas, cellSize);
    _drawCentre(canvas, boardSize, cellSize);
    _drawSafeZoneStars(canvas, cellSize);
    if (state != null) {
      if (activeCapture != null) {
        _drawCaptureHalo(canvas, cellSize);
      }
      _drawPawns(canvas, cellSize);
    }

    canvas.restore();
  }

  void _drawBoardBackdrop(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2A1A57), Color(0xFF1A1038), Color(0xFF10092A)],
        stops: [0.0, 0.62, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 1.06,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.18),
          Colors.black.withOpacity(0.36),
        ],
        stops: const [0.5, 0.82, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize) {
    // Clip grid to the cross shape – exclude the 4 corner base zones (6×6 each)
    canvas.save();
    final clip = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(0, 0, 6 * cellSize, 6 * cellSize))
      ..addRect(Rect.fromLTWH(9 * cellSize, 0, 6 * cellSize, 6 * cellSize))
      ..addRect(
          Rect.fromLTWH(9 * cellSize, 9 * cellSize, 6 * cellSize, 6 * cellSize))
      ..addRect(Rect.fromLTWH(0, 9 * cellSize, 6 * cellSize, 6 * cellSize));
    clip.fillType = PathFillType.evenOdd;
    canvas.clipPath(clip);

    final gridPaint = Paint()
      ..color = const Color(0xFFD6DDFF).withOpacity(0.18)
      ..strokeWidth = 0.95
      ..style = PaintingStyle.stroke;

    // Paint all outer-path cells with gradient fill for depth.
    for (final cell in BoardLayout.outerPath) {
      final rect = Rect.fromLTWH(
        cell.$2 * cellSize + 0.5,
        cell.$1 * cellSize + 0.5,
        cellSize - 1,
        cellSize - 1,
      );

      // Gradient for depth perception
      final cellGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.88),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, cellGradient);

      // Subtle shadow on bottom-right
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black.withOpacity(0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    final laneHighlight = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(6 * cellSize, 0, 3 * cellSize, 15 * cellSize),
        laneHighlight);
    canvas.drawRect(Rect.fromLTWH(0, 6 * cellSize, 15 * cellSize, 3 * cellSize),
        laneHighlight);

    // Subtle diagonal texture for white path cells.
    final texturePaint = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..strokeWidth = 1.0;
    for (double x = -size.height; x < size.width; x += cellSize * 0.44) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        texturePaint,
      );
    }

    for (int i = 0; i <= 15; i++) {
      canvas.drawLine(Offset(i * cellSize, 0),
          Offset(i * cellSize, size.height), gridPaint);
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

      // Outer player zone with gradient for depth.
      final bgRect = Rect.fromLTWH(
        r.left * cellSize,
        r.top * cellSize,
        r.width * cellSize,
        r.height * cellSize,
      );
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.withOpacity(1.0),
            Color.lerp(c, Colors.black, 0.15)!,
          ],
        ).createShader(bgRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
        gradientPaint,
      );

      // Shadow effect
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left * cellSize + 2,
            r.top * cellSize + r.height * cellSize - 4,
            r.width * cellSize - 4,
            3,
          ),
          const Radius.circular(1),
        ),
        shadowPaint,
      );

      // Outer border of the player zone.
      final borderPaint = Paint()
        ..color = Color.lerp(c, Colors.black, 0.28)!
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          r.left * cellSize + 1,
          r.top * cellSize + 1,
          r.width * cellSize - 2,
          r.height * cellSize - 2,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(rr, borderPaint);

      // Inner white square with player-color contour.
      final innerRect = Rect.fromLTWH(
        (r.left + 1) * cellSize,
        (r.top + 1) * cellSize,
        4 * cellSize,
        4 * cellSize,
      );

      // Inner gradient for depth
      final innerGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.88),
          ],
        ).createShader(innerRect);
      canvas.drawRect(innerRect, innerGradient);

      // Inner shadow
      canvas.drawRect(
        innerRect,
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Color contour
      canvas.drawRect(
        innerRect,
        Paint()
          ..color = Color.lerp(c, Colors.black, 0.24)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );

      // Radial light effect for volume
      final innerCirclePaint = Paint()..color = c.withOpacity(0.12);
      final centerX = (r.left + r.width / 2) * cellSize;
      final centerY = (r.top + r.height / 2) * cellSize;
      canvas.drawCircle(
        Offset(centerX, centerY),
        r.width * cellSize * 0.36,
        innerCirclePaint,
      );
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
      for (int i = 0; i < entry.value.length - 1; i++) {
        final cell = entry.value[i];
        final rect = Rect.fromLTWH(cell.$2 * cellSize + 1,
            cell.$1 * cellSize + 1, cellSize - 2, cellSize - 2);

        // Gradient for depth
        final gradientPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.95),
              Color.lerp(color, Colors.black, 0.08)!.withOpacity(0.90),
            ],
          ).createShader(rect);
        canvas.drawRect(rect, gradientPaint);

        // Highlight
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.white.withOpacity(0.32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawEntryArrows(Canvas canvas, double cellSize) {
    final entries = [
      (PlayerColor.red, const Color(0xFFE53935)),
      (PlayerColor.blue, const Color(0xFF1E88E5)),
      (PlayerColor.green, const Color(0xFF43A047)),
      (PlayerColor.yellow, const Color(0xFFFDD835)),
    ];

    for (final entry in entries) {
      final idx = entry.$1.startPosition;
      final cell = BoardLayout.outerPath[idx];
      final next =
          BoardLayout.outerPath[(idx + 1) % BoardLayout.outerPath.length];

      final cx = cell.$2 * cellSize + cellSize / 2;
      final cy = cell.$1 * cellSize + cellSize / 2;
      final dx = (next.$2 - cell.$2).toDouble();
      final dy = (next.$1 - cell.$1).toDouble();
      final angle = math.atan2(dy, dx);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      final p = Path()
        ..moveTo(cellSize * 0.22, 0)
        ..lineTo(-cellSize * 0.16, -cellSize * 0.19)
        ..lineTo(-cellSize * 0.16, -cellSize * 0.07)
        ..lineTo(-cellSize * 0.30, -cellSize * 0.07)
        ..lineTo(-cellSize * 0.30, cellSize * 0.07)
        ..lineTo(-cellSize * 0.16, cellSize * 0.07)
        ..lineTo(-cellSize * 0.16, cellSize * 0.19)
        ..close();

      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.black.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.3),
      );

      final arrowRect = Rect.fromCenter(
        center: Offset.zero,
        width: cellSize * 0.62,
        height: cellSize * 0.42,
      );
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Color.lerp(entry.$2, Colors.white, 0.22)!,
              Color.lerp(entry.$2, Colors.black, 0.08)!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(arrowRect),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white.withOpacity(0.68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      canvas.restore();
    }
  }

  void _drawCentre(Canvas canvas, Size size, double cellSize) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cellSize * 1.5;

    // Draw a coloured triangle for each quadrant with gradient
    final colours = [
      (
        const Color(0xFF1E88E5),
        [Offset(cx, cy), Offset(cx - r, cy - r), Offset(cx + r, cy - r)]
      ), // top=blue
      (
        const Color(0xFF43A047),
        [Offset(cx, cy), Offset(cx + r, cy - r), Offset(cx + r, cy + r)]
      ), // right=green
      (
        const Color(0xFFFDD835),
        [Offset(cx, cy), Offset(cx + r, cy + r), Offset(cx - r, cy + r)]
      ), // bottom=yellow
      (
        const Color(0xFFE53935),
        [Offset(cx, cy), Offset(cx - r, cy + r), Offset(cx - r, cy - r)]
      ), // left=red
    ];

    for (final tri in colours) {
      final path = Path()
        ..moveTo(tri.$2[0].dx, tri.$2[0].dy)
        ..lineTo(tri.$2[1].dx, tri.$2[1].dy)
        ..lineTo(tri.$2[2].dx, tri.$2[2].dy)
        ..close();

      final rect = Rect.fromLTWH(cx - r, cy - r, r * 2, r * 2);
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomRight,
          colors: [
            tri.$1.withOpacity(1.0),
            Color.lerp(tri.$1, Colors.black, 0.12)!,
          ],
        ).createShader(rect);
      canvas.drawPath(path, gradientPaint);

      // Add border highlight
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Central shine effect
    final centerGlow = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy), cellSize * 0.8, centerGlow);
  }

  void _drawSafeZoneStars(Canvas canvas, double cellSize) {
    const startCellColors = {
      0: Color(0xFFE53935),
      13: Color(0xFF1E88E5),
      26: Color(0xFF43A047),
      39: Color(0xFFFDD835),
    };

    for (final idx in safeZones) {
      if (idx < 0 || idx >= BoardLayout.outerPath.length) continue;
      final cell = BoardLayout.outerPath[idx];
      final left = cell.$2 * cellSize;
      final top = cell.$1 * cellSize;
      final cx = left + cellSize / 2;
      final cy = top + cellSize / 2;

      final startColor = startCellColors[idx];
      if (startColor != null) {
        final cellRect =
            Rect.fromLTWH(left + 0.5, top + 0.5, cellSize - 1, cellSize - 1);

        // Gradient for start cells
        final gradientPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              startColor.withOpacity(0.95),
              Color.lerp(startColor, Colors.black, 0.10)!.withOpacity(0.90),
            ],
          ).createShader(cellRect);
        canvas.drawRect(cellRect, gradientPaint);

        // Highlight
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = Colors.white.withOpacity(0.28)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        continue;
      }

      // Gold background with gradient
      final goldRect = Rect.fromLTWH(left + 0.5, top + 0.5, cellSize - 1, cellSize - 1);
      final goldGradient = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF8DC),
            const Color(0xFFFFE082),
          ],
        ).createShader(goldRect);
      canvas.drawRect(goldRect, goldGradient);

      // 5-pointed star
      final star = _buildStarPath(cx, cy, cellSize * 0.38, cellSize * 0.16);

      // Star shadow
      canvas.drawPath(
        star,
        Paint()
          ..color = Colors.black.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Star fill
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFC107));

      // Star highlight
      canvas.drawPath(
        star,
        Paint()
          ..color = Colors.white.withOpacity(0.40)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      // Star border
      canvas.drawPath(
        star,
        Paint()
          ..color = const Color(0xFFFF8F00)
          ..strokeWidth = 0.9
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
        if (_isCaptureReservedPawn(pi, i)) continue;
        // Skip the pawn currently being animated (drawn separately below)
        if (activeMove != null &&
            pi == activeMove!.playerIdx &&
            i == activeMove!.pawnIdx) continue;
        _drawSinglePawn(canvas, cellSize, player.pawns[i], pi, i, s);
      }
    }

    // Keep captured pawns visible on their captured cell until the attacker arrives.
    if (pendingCapture != null) {
      _drawPendingCapturedPawns(canvas, cellSize, s);
    }

    // Animated pawn drawn last so it renders on top
    if (activeMove != null) _drawAnimatedPawn(canvas, cellSize, s);
    if (activeCapture != null) {
      _drawCapturedPawnsSlide(canvas, cellSize);
    }
  }

  bool _isCaptureReservedPawn(int playerIdx, int pawnIdx) {
    bool inCapture(CaptureEffectInfo? capture) {
      if (capture == null) return false;
      return capture.capturedPawns
          .any((p) => p.playerIdx == playerIdx && p.pawnIdx == pawnIdx);
    }

    return inCapture(activeCapture) || inCapture(pendingCapture);
  }

  void _drawPendingCapturedPawns(Canvas canvas, double cellSize, GameState s) {
    final capture = pendingCapture;
    if (capture == null) return;

    for (final p in capture.capturedPawns) {
      final off = _resolveOffset(p.fromPosition, p.color, p.pawnIdx, cellSize);
      final stack = _stackOffsetForPosition(
        s,
        p.fromPosition,
        p.playerIdx,
        p.pawnIdx,
        cellSize,
      );
      final cx = off.$1 + stack.$1;
      final cy = off.$2 + stack.$2;
      paintAnimalPawn(canvas,
          cx: cx,
          baseY: cy + cellSize * 0.32,
          cellSize: cellSize,
          color: p.color);
    }
  }

  void _drawCaptureHalo(Canvas canvas, double cellSize) {
    final capture = activeCapture;
    if (capture == null) return;
    final pos = capture.captureCellPosition;
    if (pos < 0 || pos >= BoardLayout.outerPath.length) return;

    final cell = BoardLayout.outerPath[pos];
    final left = cell.$2 * cellSize;
    final top = cell.$1 * cellSize;
    final rect = Rect.fromLTWH(left + 1, top + 1, cellSize - 2, cellSize - 2);
    final t = captureProgress.clamp(0.0, 1.0);
    final pulse = 0.7 + 0.3 * math.sin(t * math.pi * 5);

    final glowPaint = Paint()
      ..color = Colors.red.withOpacity((0.40 * (1 - t) + 0.22) * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    final borderPaint = Paint()
      ..color = Colors.red.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    final fillPaint = Paint()..color = Colors.red.withOpacity(0.10 * (1 - t));

    final rr = RRect.fromRectAndRadius(rect, Radius.circular(cellSize * 0.12));
    canvas.drawRRect(rr, fillPaint);
    canvas.drawRRect(rr, glowPaint);
    canvas.drawRRect(rr, borderPaint);
  }

  void _drawCapturedPawnsSlide(Canvas canvas, double cellSize) {
    final capture = activeCapture;
    if (capture == null) return;
    final t = Curves.easeInOutCubic.transform(captureProgress.clamp(0.0, 1.0));

    for (final p in capture.capturedPawns) {
      final from = _resolveOffset(p.fromPosition, p.color, p.pawnIdx, cellSize);
      final to = BoardLayout.basePositionOffset(p.color, p.pawnIdx, cellSize);

      final cx = from.$1 + (to.$1 - from.$1) * t;
      final cy = from.$2 + (to.$2 - from.$2) * t;
      final bottomY = cy + cellSize * 0.32;
      paintAnimalPawn(canvas,
          cx: cx, baseY: bottomY, cellSize: cellSize, color: p.color);
    }
  }

  // Interpolated hop animation – advances one cell at a time
  void _drawAnimatedPawn(Canvas canvas, double cellSize, GameState s) {
    final move = activeMove!;
    final pawn = s.players[move.playerIdx].pawns[move.pawnIdx];
    final path = move.path;

    if (path.isEmpty) return;

    final numSteps = path.length;
    final totalT = animProgress.clamp(0.0, 1.0);
    final scaledT = totalT * numSteps;
    final stepIdx = scaledT.floor().clamp(0, numSteps - 1);
    final stepT = (scaledT - stepIdx).clamp(0.0, 1.0);

    final fromPos = stepIdx == 0 ? move.fromPosition : path[stepIdx - 1];
    final toPos = path[stepIdx];

    final from = _resolveOffset(fromPos, move.color, move.pawnIdx, cellSize);
    final to = _resolveOffset(toPos, move.color, move.pawnIdx, cellSize);

    final t = Curves.easeInOut.transform(stepT);
    final cx = from.$1 + (to.$1 - from.$1) * t;
    final cy = from.$2 + (to.$2 - from.$2) * t;
    final hop = cellSize * 0.85 * math.sin(math.pi * t); // hop height per step

    paintAnimalPawn(canvas,
        cx: cx,
        baseY: cy - hop + cellSize * 0.33,
        cellSize: cellSize,
        color: pawn.color);
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
      final off = BoardLayout.basePositionOffset(pawn.color, pawnIdx, cellSize);
      cx = off.$1;
      cy = off.$2;
    } else {
      final off =
          BoardLayout.positionToOffset(pawn.position, pawn.color, cellSize);
      cx = off.$1;
      cy = off.$2;

      final stack = _stackOffsetForPosition(
          s, pawn.position, playerIdx, pawnIdx, cellSize);
      cx += stack.$1;
      cy += stack.$2;
    }

    final isCurrentPlayer = playerIdx == s.currentPlayerIndex;
    final isMovable = isCurrentPlayer &&
        highlightedPawnIndices.contains(pawnIdx) &&
        s.phase == GamePhase.choosingPawn;

    // Vertical centre of the cell → pawn base sits slightly below centre
    final bottomY = cy + cellSize * 0.32;
    paintAnimalPawn(canvas,
        cx: cx,
        baseY: bottomY,
        cellSize: cellSize,
        color: pawn.color,
        isMovable: isMovable);
  }

  (double, double) _stackOffsetForPosition(
      GameState s, int position, int playerIdx, int pawnIdx, double cellSize) {
    if (position < 0) return (0, 0);

    final occupants = <({int playerIdx, int pawnIdx})>[];

    for (int pi = 0; pi < s.players.length; pi++) {
      final player = s.players[pi];
      for (int i = 0; i < player.pawns.length; i++) {
        final pawn = player.pawns[i];
        if (pawn.position != position) continue;
        if (activeMove != null &&
            pi == activeMove!.playerIdx &&
            i == activeMove!.pawnIdx) {
          continue;
        }
        if (_isCaptureReservedPawn(pi, i)) continue;
        occupants.add((playerIdx: pi, pawnIdx: i));
      }
    }

    // Pending captured pawns are still shown on the captured cell until impact.
    if (pendingCapture != null) {
      for (final cp in pendingCapture!.capturedPawns) {
        if (cp.fromPosition != position) continue;
        final exists = occupants.any(
          (o) => o.playerIdx == cp.playerIdx && o.pawnIdx == cp.pawnIdx,
        );
        if (!exists) {
          occupants.add((playerIdx: cp.playerIdx, pawnIdx: cp.pawnIdx));
        }
      }
    }

    occupants.sort((a, b) {
      final byPlayer = a.playerIdx.compareTo(b.playerIdx);
      if (byPlayer != 0) return byPlayer;
      return a.pawnIdx.compareTo(b.pawnIdx);
    });

    final count = occupants.length;
    if (count <= 1) return (0, 0);

    final selfIndex = occupants.indexWhere(
      (o) => o.playerIdx == playerIdx && o.pawnIdx == pawnIdx,
    );
    if (selfIndex < 0) return (0, 0);

    final spread = cellSize * 0.16;
    final positions = <(double, double)>[];
    if (count == 2) {
      positions.add((-spread, 0));
      positions.add((spread, 0));
    } else if (count == 3) {
      positions.add((-spread, -spread * 0.55));
      positions.add((spread, -spread * 0.55));
      positions.add((0, spread));
    } else if (count == 4) {
      positions.add((-spread, -spread));
      positions.add((spread, -spread));
      positions.add((-spread, spread));
      positions.add((spread, spread));
    } else {
      for (int i = 0; i < count; i++) {
        final a = (2 * math.pi * i) / count;
        positions.add((math.cos(a) * spread * 1.2, math.sin(a) * spread * 1.2));
      }
    }

    final chosen = positions[selfIndex.clamp(0, positions.length - 1)];
    return chosen;
  }

  @override
  bool shouldRepaint(LudoBoardPainter oldDelegate) => true;
}
