import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1035),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Title
            _buildTitle(),
            const SizedBox(height: 48),
            // Menu buttons
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                children: [
                  _MenuButton(
                    icon: Icons.computer,
                    label: 'Vs Ordinateur',
                    subtitle: '1 humain vs 3 IA',
                    color: const Color(0xFF7C4DFF),
                    onTap: () => _startGame(context, GameMode.vsComputer),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.people,
                    label: 'Multijoueur Local',
                    subtitle: '2 à 4 joueurs sur cet appareil',
                    color: const Color(0xFF00BCD4),
                    onTap: () =>
                        _showPlayerCountDialog(context),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.school,
                    label: 'Apprendre',
                    subtitle: 'Maîtrise les règles étape par étape',
                    color: const Color(0xFF4CAF50),
                    onTap: () =>
                        Navigator.pushNamed(context, '/learn'),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    icon: Icons.settings,
                    label: 'Paramètres',
                    subtitle: 'Sons, thèmes...',
                    color: const Color(0xFF607D8B),
                    onTap: () =>
                        Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('v1.0.0 · Ludo King HD',
                  style: TextStyle(color: Colors.white30, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text('👑', style: TextStyle(fontSize: 60))
            .animate()
            .scale(duration: 800.ms, curve: Curves.elasticOut),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF6F00)],
          ).createShader(bounds),
          child: const Text(
            'LUDO KING HD',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.3),
        const SizedBox(height: 4),
        const Text(
          'Le jeu des Petits Chevaux',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  void _startGame(BuildContext context, GameMode mode,
      {int playerCount = 4}) {
    final allColors = PlayerColor.values;
    final colors = allColors.take(playerCount).toList();
    context.read<GameProvider>().startGame(mode, colors);
    Navigator.pushNamed(context, '/game');
  }

  Future<void> _showPlayerCountDialog(BuildContext context) async {
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => _PlayerCountDialog(),
    );
    if (count != null && context.mounted) {
      _startGame(context, GameMode.localMultiplayer, playerCount: count);
    }
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color.withOpacity(0.55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

class _PlayerCountDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D1B69),
      title: const Text('Nombre de joueurs',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [2, 3, 4].map((n) {
          return ListTile(
            title: Text('$n joueurs',
                style: const TextStyle(color: Colors.white)),
            leading: const Icon(Icons.person, color: Colors.white70),
            onTap: () => Navigator.pop(context, n),
          );
        }).toList(),
      ),
    );
  }
}
