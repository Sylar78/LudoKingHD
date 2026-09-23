import '../models/player_color.dart';

/// Maps a PlayerColor + pawn absolute position to pixel (x,y) on a 15×15 grid.
/// The board is drawn on a normalized 15-unit grid; callers scale as needed.
///
/// Outer path: 52 squares (indices 0-51)
/// Home columns: 6 squares per colour (indices 100-105)
/// Centre: position 105 (for all colours)
///
/// Grid layout (0-indexed, row, col):
///
///     6 col strips of 3 + center 3 = 15 cols
///     Each arm is 3 wide, each outer row is 1.
///
/// The standard Ludo 15×15 grid is used here.

class BoardLayout {
  // --- Outer path positions (52 cells, clockwise starting from Red's entry) ---
  // Each entry is (row, col) on the 15×15 grid
  static const List<(int, int)> outerPath = [
    // Red start → right side going down (col 6, rows 1-5)
    (6, 1), (6, 2), (6, 3), (6, 4), (6, 5), // 0-4
    // top-left corner going right
    (5, 6), (4, 6), (3, 6), (2, 6), (1, 6), // 5-9
    (0, 6), // 10
    // top middle going right
    (0, 7), // 11
    // Blue start (top-right area)
    (0, 8), (1, 8), (2, 8), (3, 8), (4, 8), // 12-16 (13=Blue start)
    (5, 8), // 17
    // top-right corner going down
    (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), // 18-22
    (6, 14), // 23
    // right middle going down
    (7, 14), // 24
    // Green start
    (8, 14), (8, 13), (8, 12), (8, 11), (8, 10),
    (8, 9), // 25-30 (26=Green start)
    // bottom-right going left
    (9, 8), // 31
    (10, 8), (11, 8), (12, 8), (13, 8), (14, 8), // 32-36
    (14, 7), // 37
    // bottom middle
    (14, 6), // 38
    // Yellow start
    (13, 6), (12, 6), (11, 6), (10, 6), (9, 6), // 39-43 (39=Yellow start)
    (8, 5), // 44
    (8, 4), (8, 3), (8, 2), (8, 1), (8, 0), // 45-49
    (7, 0), // 50
    (6, 0), // 51 (wraps back near Red)
  ];

  // --- Home columns (per colour, 5 cells + centre) ---
  static const Map<PlayerColor, List<(int, int)>> homeColumns = {
    PlayerColor.red: [
      (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 7), // 100-105
    ],
    PlayerColor.blue: [
      (1, 7),
      (2, 7),
      (3, 7),
      (4, 7),
      (5, 7),
      (7, 7),
    ],
    PlayerColor.green: [
      (7, 13),
      (7, 12),
      (7, 11),
      (7, 10),
      (7, 9),
      (7, 7),
    ],
    PlayerColor.yellow: [
      (13, 7),
      (12, 7),
      (11, 7),
      (10, 7),
      (9, 7),
      (7, 7),
    ],
  };

  // --- Base positions (4 pawns per base) – symmetrically centred inside each circle ---
  static const Map<PlayerColor, List<(int, int)>> basePositions = {
    PlayerColor.red: [(1, 1), (1, 4), (4, 1), (4, 4)],
    PlayerColor.blue: [(1, 10), (1, 13), (4, 10), (4, 13)],
    PlayerColor.green: [(10, 10), (10, 13), (13, 10), (13, 13)],
    PlayerColor.yellow: [(10, 1), (10, 4), (13, 1), (13, 4)],
  };

  static (double, double) cellToOffset(int row, int col, double cellSize) {
    return (col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
  }

  /// Get pixel center for a pawn at [position].
  static (double, double) positionToOffset(
      int position, PlayerColor color, double cellSize) {
    if (position == -1) {
      // In base — caller handles
      return (0, 0);
    }
    if (position >= 0 && position <= 51) {
      final cell = outerPath[position];
      return cellToOffset(cell.$1, cell.$2, cellSize);
    }
    // Home column: 100..105
    final homeIdx = position - 100;
    final cols = homeColumns[color]!;
    if (homeIdx < cols.length) {
      final cell = cols[homeIdx];
      return cellToOffset(cell.$1, cell.$2, cellSize);
    }
    return (0, 0);
  }

  static (double, double) basePositionOffset(
      PlayerColor color, int pawnIndex, double cellSize) {
    final positions = basePositions[color]!;
    final cell = positions[pawnIndex % 4];
    return cellToOffset(cell.$1, cell.$2, cellSize);
  }
}
