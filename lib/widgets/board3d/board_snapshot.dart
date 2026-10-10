import '../../models/game_state.dart';
import '../../models/move_info.dart';
import '../../models/player_color.dart';

/// Ce que la scène 3D doit savoir de la partie, sous une forme qui passe en
/// JSON dans la WebView (lu par `window.ludoBoard.apply`, board3d/src/main.js).
///
/// Seules les positions voyagent : la page connaît la même grille que
/// [BoardLayout] (board3d/src/layout.json, gardé en phase par un test) et en
/// déduit les cases. Le dernier coup et la dernière capture portent leur
/// numéro de version, pour que la page ne rejoue une animation qu'une fois.
Map<String, Object?> boardSnapshot(
  GameState state, {
  LastMoveInfo? lastMove,
  int moveVersion = 0,
  CaptureEffectInfo? lastCapture,
  int captureVersion = 0,
}) {
  return {
    'players': [
      for (final player in state.players)
        {
          'color': colorKey(player.color),
          'pawns': [for (final pawn in player.pawns) pawn.position],
        },
    ],
    'current': state.currentPlayerIndex,
    'phase': state.phase.name,
    'movable': state.phase == GamePhase.choosingPawn
        ? List<int>.of(state.movablePawnIndices)
        : const <int>[],
    if (lastMove != null)
      'move': {
        'version': moveVersion,
        'player': lastMove.playerIdx,
        'pawn': lastMove.pawnIdx,
        'fromPos': lastMove.fromPosition,
        'path': lastMove.path,
      },
    if (lastCapture != null)
      'capture': {
        'version': captureVersion,
        'cellPos': lastCapture.captureCellPosition,
        'pawns': [
          for (final p in lastCapture.capturedPawns)
            {
              'player': p.playerIdx,
              'pawn': p.pawnIdx,
              'fromPos': p.fromPosition
            },
        ],
      },
  };
}

/// Le nom de couleur attendu par la scène, indépendant des libellés affichés.
String colorKey(PlayerColor color) => switch (color) {
      PlayerColor.red => 'red',
      PlayerColor.blue => 'blue',
      PlayerColor.green => 'green',
      PlayerColor.yellow => 'yellow',
    };
