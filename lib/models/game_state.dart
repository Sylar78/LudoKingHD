import 'player.dart';
import 'player_color.dart';

enum GameMode { vsComputer, localMultiplayer }

enum GamePhase { rolling, choosingPawn, animating, gameOver }

class GameState {
  final List<Player> players;
  final GameMode mode;

  int currentPlayerIndex;
  int diceValue;
  bool hasRolled;
  GamePhase phase;
  List<int> movablePawnIndices; // indices within current player's pawns
  String? message;
  int? winnerIndex;
  List<int> finishedPlayerIndices;

  GameState({
    required this.players,
    required this.mode,
    this.currentPlayerIndex = 0,
    this.diceValue = 1,
    this.hasRolled = false,
    this.phase = GamePhase.rolling,
    List<int>? movablePawnIndices,
    this.message,
    this.winnerIndex,
    List<int>? finishedPlayerIndices,
  })  : movablePawnIndices = movablePawnIndices ?? [],
        finishedPlayerIndices = finishedPlayerIndices ?? [];

  Player get currentPlayer => players[currentPlayerIndex];

  static GameState initial(GameMode mode, List<PlayerColor> colors) {
    final players = colors.map((c) {
      final type = (mode == GameMode.vsComputer && c != colors.first)
          ? PlayerType.computer
          : PlayerType.human;
      return Player(color: c, type: type);
    }).toList();
    return GameState(players: players, mode: mode);
  }
}
