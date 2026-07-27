/// Safe zones on the outer path (52 squares).
/// Pawns on these squares cannot be captured.
const Set<int> safeZones = {
  // Near each start position
  0, 8, 13, 21, 26, 34, 39, 47,
};
