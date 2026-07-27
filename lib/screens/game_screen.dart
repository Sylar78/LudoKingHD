import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/player_info_panel.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.state;

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B69),
        foregroundColor: Colors.white,
        title: const Text('Ludo King HD',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Recommencer',
            onPressed: () => _confirmRestart(context, provider),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Joueurs haut : Rouge (0) + Bleu (1) ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final p in state.players.take(2))
                    PlayerInfoPanel(
                      player: p,
                      isActive: state.players.indexOf(p) == state.currentPlayerIndex,
                    ),
                ],
              ),
            ),

            // Board
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const LudoBoardWidget(),
              ),
            ),

            // ── Joueurs bas : Jaune (3) + Vert (2) ──────────────────────
            if (state.players.length > 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final p in state.players.length == 4
                        ? [state.players[3], state.players[2]]
                        : state.players.skip(2).toList())
                      PlayerInfoPanel(
                        player: p,
                        isActive: state.players.indexOf(p) == state.currentPlayerIndex,
                      ),
                  ],
                ),
              ),

            // Message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  state.message ?? '',
                  key: ValueKey(state.message),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Dice + roll button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DiceWidget(
                    value: state.diceValue,
                    isRolling: provider.diceRolling,
                    enabled: !state.hasRolled &&
                        state.phase == GamePhase.rolling &&
                        state.currentPlayer.type.name == 'human',
                    onRoll: () => provider.rollDice(),
                  ),
                  const SizedBox(width: 20),
                  if (!state.hasRolled &&
                      state.phase == GamePhase.rolling &&
                      state.currentPlayer.type.name == 'human')
                    ElevatedButton.icon(
                      onPressed: () => provider.rollDice(),
                      icon: const Icon(Icons.casino),
                      label: const Text('Lancer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ).animate().scale(duration: 200.ms),
                  if (state.phase == GamePhase.choosingPawn)
                    Text(
                      'Touchez un pion brillant',
                      style: TextStyle(
                          color: Colors.amber.shade300,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRestart(
      BuildContext context, GameProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recommencer ?'),
        content: const Text('Voulez-vous vraiment recommencer la partie ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      provider.reset();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Game Over overlay ────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameProvider>().state;
    if (state == null || state.phase != GamePhase.gameOver) {
      return const SizedBox.shrink();
    }

    final winner = state.players[state.winnerIndex!];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2D1B69),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: winner.color.color, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆',
                  style: TextStyle(fontSize: 56))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),
              Text(
                '${winner.color.name} gagne !',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: winner.color.color),
              ),
              const SizedBox(height: 8),
              // Rankings
              ...(() {
                final ranked = state.players
                    .where((p) => p.finishRank > 0)
                    .toList()
                  ..sort((a, b) => a.finishRank.compareTo(b.finishRank));
                return ranked
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${p.finishRank}. ',
                                  style: const TextStyle(color: Colors.white70)),
                              Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p.color.color)),
                              const SizedBox(width: 6),
                              Text(p.color.name,
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ))
                    .toList();
              })(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.read<GameProvider>().reset();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: winner.color.color,
                    foregroundColor: Colors.white),
                child: const Text('Menu principal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
