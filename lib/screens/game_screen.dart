import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
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
      backgroundColor: const Color(0xFF130B2D),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('LUDO KING HD',
            style: AppText.display(size: 18, letterSpacing: 1.4)),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'Recommencer',
            onPressed: () => _confirmRestart(context, provider),
          ),
        ],
      ),
      body: AppBackground(
        // Pas de halos ici : l'ecran est dense, le plateau doit rester le
        // point le plus lumineux.
        showGlows: false,
        child: SafeArea(
          child: Column(
            children: [
              _RangeeDeJoueurs(state: state, indices: _hautIndices(state)),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  // Le plateau est carre : sans ca, le cadre dore s'etirait sur
                  // toute la hauteur disponible et laissait deux grandes bandes
                  // vides au-dessus et au-dessous.
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xAA32236F), Color(0xAA1A1244)],
                          ),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.30),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.40),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          child: LudoBoardWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (state.players.length > 2)
                _RangeeDeJoueurs(state: state, indices: _basIndices(state)),
              _BandeauMessage(message: state.message),
              _ZoneDe(state: state, provider: provider),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Les deux joueurs affichés au-dessus du plateau, puis ceux du dessous.
  /// L'ordre suit les coins du plateau : rouge et bleu en haut, jaune et vert
  /// en bas.
  static List<int> _hautIndices(GameState state) =>
      [for (var i = 0; i < state.players.length && i < 2; i++) i];

  static List<int> _basIndices(GameState state) => state.players.length == 4
      ? [3, 2]
      : [for (var i = 2; i < state.players.length; i++) i];

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

/// Une rangée de cartes de joueurs.
class _RangeeDeJoueurs extends StatelessWidget {
  final GameState state;
  final List<int> indices;

  const _RangeeDeJoueurs({required this.state, required this.indices});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final i in indices)
            PlayerInfoPanel(
              player: state.players[i],
              isActive: i == state.currentPlayerIndex,
              // Le dé ne suit que le joueur dont c'est le tour, et seulement
              // une fois lancé.
              diceValue: i == state.currentPlayerIndex && state.hasRolled
                  ? state.diceValue
                  : null,
              // « Vous » n'a de sens que contre l'ordinateur, où une seule
              // carte est tenue par la personne qui regarde. En multijoueur
              // local, les quatre l'étaient, ce qui ne distinguait rien.
              isYou: state.mode == GameMode.vsComputer &&
                  state.players[i].type == PlayerType.human,
            ),
        ],
      ),
    );
  }
}

/// La ligne qui dit ce qui vient de se passer.
class _BandeauMessage extends StatelessWidget {
  final String? message;

  const _BandeauMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Container(
          key: ValueKey(message),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Text(
            message ?? '',
            textAlign: TextAlign.center,
            // Blanc plein sur un fond sombre : l'italique gris clair d'avant
            // se lisait mal sur le dégradé.
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// Le dé et son bouton.
class _ZoneDe extends StatelessWidget {
  final GameState state;
  final GameProvider provider;

  const _ZoneDe({required this.state, required this.provider});

  @override
  Widget build(BuildContext context) {
    final aLaMain = state.phase == GamePhase.rolling &&
        !state.hasRolled &&
        state.currentPlayer.type == PlayerType.human;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiceWidget(
            value: state.diceValue,
            isRolling: provider.diceRolling,
            enabled: aLaMain,
            onRoll: provider.rollDice,
          ),
          const SizedBox(width: 18),
          if (aLaMain)
            ElevatedButton.icon(
              onPressed: provider.rollDice,
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Lancer'),
            ).animate().scale(duration: 200.ms)
          else if (state.phase == GamePhase.choosingPawn)
            Flexible(
              child: Text(
                state.currentPlayer.type == PlayerType.human
                    ? 'Touche un pion qui brille'
                    : 'L\'ordinateur réfléchit…',
                style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            )
          else if (state.currentPlayer.type == PlayerType.computer)
            const Text(
              'Au tour de l\'ordinateur…',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ── Game Over overlay ────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final state = provider.state;
    if (state == null || state.phase != GamePhase.gameOver) {
      return const SizedBox.shrink();
    }

    final gagnant = state.players[state.winnerIndex!];
    final classement = state.players.where((p) => p.finishRank > 0).toList()
      ..sort((a, b) => a.finishRank.compareTo(b.finishRank));

    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: goldFrame(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surface, AppColors.surfaceLow],
                ),
                radius: 24,
                borderWidth: 2.5,
                glow: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 56))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 10),
                  Text(
                    '${gagnant.color.name} gagne !',
                    textAlign: TextAlign.center,
                    style:
                        AppText.display(size: 26, color: gagnant.color.color),
                  ),
                  if (classement.length > 1) ...[
                    const SizedBox(height: 16),
                    for (final p in classement)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text('${p.finishRank}.',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.color.color,
                                border:
                                    Border.all(color: Colors.white24, width: 1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(p.color.name, style: AppText.body),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.reset();
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Menu'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          // Rejouer relance la même configuration : même mode,
                          // mêmes couleurs, dans le même ordre.
                          onPressed: () => provider.startGame(
                            state.mode,
                            state.players.map((p) => p.color).toList(),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: gagnant.color.color,
                              foregroundColor: Colors.white),
                          child: const Text('Rejouer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
