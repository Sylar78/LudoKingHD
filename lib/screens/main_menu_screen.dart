import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';

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
                    subtitle: 'Choix des joueurs et de votre couleur',
                    color: const Color(0xFF7C4DFF),
                    onTap: () => _showVsComputerSetupFlow(context),
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
    const allColors = PlayerColor.values;
    final colors = allColors.take(playerCount).toList();
    _startGameWithColors(context, mode, colors);
  }

  void _startGameWithColors(
      BuildContext context, GameMode mode, List<PlayerColor> colors) {
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

  Future<void> _showVsComputerSetupFlow(BuildContext context) async {
    while (context.mounted) {
      final count = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (ctx) => const _VsComputerPlayerCountDialog(),
      );

      if (count == null || !context.mounted) {
        return;
      }

      final colorSelection = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (ctx) => const _VsComputerColorDialog(),
      );

      if (colorSelection == _VsSetupFlowAction.back) {
        continue;
      }

      if (colorSelection is! PlayerColor || !context.mounted) {
        return;
      }

      final colors = _buildVsComputerColors(colorSelection, count);
      _startGameWithColors(context, GameMode.vsComputer, colors);
      return;
    }
  }

  List<PlayerColor> _buildVsComputerColors(PlayerColor humanColor, int count) {
    if (count == 2) {
      final opponent = switch (humanColor) {
        PlayerColor.red => PlayerColor.green,
        PlayerColor.green => PlayerColor.red,
        PlayerColor.blue => PlayerColor.yellow,
        PlayerColor.yellow => PlayerColor.blue,
      };
      return [humanColor, opponent];
    }

    final others = PlayerColor.values.where((c) => c != humanColor).toList();
    return [humanColor, ...others];
  }
}

enum _VsSetupFlowAction { back }

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

class _VsComputerPlayerCountDialog extends StatefulWidget {
  const _VsComputerPlayerCountDialog();

  @override
  State<_VsComputerPlayerCountDialog> createState() =>
      _VsComputerPlayerCountDialogState();
}

class _VsComputerPlayerCountDialogState
    extends State<_VsComputerPlayerCountDialog> {
  int _selectedPlayers = 2;

  @override
  Widget build(BuildContext context) {
    return _VsBlueFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECT PLAYERS', style: _VsTextStyles.title),
            const SizedBox(height: 24),
            _VsOptionRow(
              label: '2 PLAYERS',
              isSelected: _selectedPlayers == 2,
              onTap: () => setState(() => _selectedPlayers = 2),
            ),
            const SizedBox(height: 14),
            _VsOptionRow(
              label: '4 PLAYERS',
              isSelected: _selectedPlayers == 4,
              onTap: () => setState(() => _selectedPlayers = 4),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.undo_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GlowActionButton(
                    label: 'NEXT',
                    onTap: () => Navigator.pop(context, _selectedPlayers),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VsComputerColorDialog extends StatefulWidget {
  const _VsComputerColorDialog();

  @override
  State<_VsComputerColorDialog> createState() => _VsComputerColorDialogState();
}

class _VsComputerColorDialogState extends State<_VsComputerColorDialog> {
  PlayerColor _selectedColor = PlayerColor.blue;

  @override
  Widget build(BuildContext context) {
    const colors = PlayerColor.values;
    return _VsBlueFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECT YOUR COLOR', style: _VsTextStyles.title),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors
                  .map((color) => _ColorPin(color: color))
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colors
                  .map(
                    (color) => _ColorRingChoice(
                      color: color,
                      selected: _selectedColor == color,
                      onTap: () => setState(() => _selectedColor = color),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.undo_rounded,
                  onTap: () => Navigator.pop(context, _VsSetupFlowAction.back),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _GlowActionButton(
                    label: 'PLAY',
                    onTap: () => Navigator.pop(context, _selectedColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VsBlueFrame extends StatelessWidget {
  final Widget child;

  const _VsBlueFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A3D93), Color(0xFF134CAD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFC107), width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAAFFC107),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _VsTextStyles {
  static final TextStyle title = GoogleFonts.luckiestGuy(
        color: const Color(0xFFFFD54F),
        fontWeight: FontWeight.w900,
        fontSize: 26,
        letterSpacing: 1.1,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(-1, 1), blurRadius: 0),
        ],
      );

  static final TextStyle label = GoogleFonts.luckiestGuy(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 23,
        letterSpacing: 1,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          Shadow(color: Colors.black, offset: Offset(-1, 1), blurRadius: 0),
        ],
      );

  static final TextStyle action = GoogleFonts.luckiestGuy(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      );
}

class _VsOptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _VsOptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 180.ms,
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFFC107) : Colors.transparent,
                border: Border.all(
                    color: const Color(0xFFFFC107), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC107)
                        .withOpacity(isSelected ? 0.65 : 0.30),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF0A3D93), size: 38)
                  : null,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: _VsTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPin extends StatelessWidget {
  final PlayerColor color;

  const _ColorPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54,
          height: 62,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              const Icon(
                Icons.place,
                size: 60,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
              Positioned(
                top: 11,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorRingChoice extends StatelessWidget {
  final PlayerColor color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorRingChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: 180.ms,
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFF46C7FF) : Colors.transparent,
          border: Border.all(color: color.color, width: 5.4),
          boxShadow: [
            BoxShadow(
              color: color.color.withOpacity(selected ? 0.55 : 0.20),
              blurRadius: selected ? 14 : 8,
              spreadRadius: selected ? 2 : 1,
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 38)
            : null,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D99FF), Color(0xFF165FC2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFC107), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x88FFC107),
                blurRadius: 12,
                spreadRadius: 1),
          ],
        ),
        child: Icon(icon, color: const Color(0xFFFFD54F), size: 36),
      ),
    );
  }
}

class _GlowActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlowActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C93FF), Color(0xFF1456B4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFC107), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x88FFC107),
                blurRadius: 12,
                spreadRadius: 1),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: _VsTextStyles.action,
          ),
        ),
      ),
    );
  }
}
