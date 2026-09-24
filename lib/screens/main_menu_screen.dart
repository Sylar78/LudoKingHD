import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/game_state.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/arcade.dart';
import '../widgets/pawn_figures.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            // Le menu tenait dans un ListView etire sur toute la hauteur, ce
            // qui laissait un grand vide sous le dernier bouton. Il est
            // maintenant centre, et borne pour rester lisible sur tablette.
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 36),
                    _MenuButton(
                      icon: Icons.smart_toy_rounded,
                      label: 'Contre l\'ordinateur',
                      subtitle: 'Choisis le nombre de joueurs et ta couleur',
                      color: AppColors.violet,
                      onTap: () => _flotVsOrdinateur(context),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.groups_rounded,
                      label: 'Multijoueur local',
                      subtitle: '2 à 4 joueurs sur cet appareil',
                      color: const Color(0xFF00ACC1),
                      onTap: () => _flotMultijoueur(context),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.menu_book_rounded,
                      label: 'Apprendre',
                      subtitle: 'Les règles, étape par étape',
                      color: const Color(0xFF43A047),
                      onTap: () => Navigator.pushNamed(context, '/learn'),
                    ),
                    const SizedBox(height: 14),
                    _MenuButton(
                      icon: Icons.tune_rounded,
                      label: 'Paramètres',
                      subtitle: 'Sons et affichage',
                      color: const Color(0xFF607D8B),
                      onTap: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Les deux parcours de lancement ────────────────────────────────────────

  Future<void> _flotMultijoueur(BuildContext context) async {
    final nombre = await showDialog<int>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _NombreDeJoueursDialog(
        titre: 'COMBIEN DE JOUEURS ?',
        choix: [2, 3, 4],
      ),
    );
    if (nombre == null || !context.mounted) return;
    _lancer(context, GameMode.localMultiplayer,
        PlayerColor.values.take(nombre).toList());
  }

  Future<void> _flotVsOrdinateur(BuildContext context) async {
    while (context.mounted) {
      final nombre = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (_) => const _NombreDeJoueursDialog(
          titre: 'COMBIEN DE JOUEURS ?',
          choix: [2, 3, 4],
        ),
      );
      if (nombre == null || !context.mounted) return;

      final choix = await showDialog<Object>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder: (_) => const _ChoixCouleurDialog(),
      );

      // Le bouton retour ramène au choix du nombre de joueurs.
      if (choix == _EtapeAction.retour) continue;
      if (choix is! PlayerColor || !context.mounted) return;

      _lancer(context, GameMode.vsComputer, _couleurs(choix, nombre));
      return;
    }
  }

  void _lancer(
      BuildContext context, GameMode mode, List<PlayerColor> couleurs) {
    context.read<GameProvider>().startGame(mode, couleurs);
    Navigator.pushNamed(context, '/game');
  }

  /// L'humain d'abord, puis ses adversaires. À deux, on prend la couleur d'en
  /// face : le plateau reste équilibré.
  static List<PlayerColor> _couleurs(PlayerColor humain, int nombre) {
    if (nombre == 2) {
      final adversaire = switch (humain) {
        PlayerColor.red => PlayerColor.green,
        PlayerColor.green => PlayerColor.red,
        PlayerColor.blue => PlayerColor.yellow,
        PlayerColor.yellow => PlayerColor.blue,
      };
      return [humain, adversaire];
    }
    final autres = PlayerColor.values.where((c) => c != humain).toList();
    return [humain, ...autres.take(nombre - 1)];
  }
}

enum _EtapeAction { retour }

// ── Le titre ────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.gold.withOpacity(0.35),
              AppColors.gold.withOpacity(0),
            ]),
          ),
          child: const Text('👑', style: TextStyle(fontSize: 58)),
        ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFE082), AppColors.gold, Color(0xFFFF8F00)],
          ).createShader(bounds),
          child: Text(
            'LUDO KING HD',
            textAlign: TextAlign.center,
            style: AppText.display(size: 34, letterSpacing: 2),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.25),
        const SizedBox(height: 6),
        const Text(
          'Le jeu des petits chevaux',
          style: TextStyle(
              color: Colors.white60, fontSize: 13, letterSpacing: 0.6),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}

// ── Les entrées du menu ─────────────────────────────────────────────────────

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
              colors: [color.withOpacity(0.92), color.withOpacity(0.58)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            // Un liseré clair en haut : la carte accroche la lumière au lieu
            // d'être un simple aplat.
            border: Border.all(color: Colors.white.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.28), width: 1.3),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.75)),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.08);
  }
}

// ── Les dialogues ───────────────────────────────────────────────────────────

class _NombreDeJoueursDialog extends StatefulWidget {
  final String titre;
  final List<int> choix;

  const _NombreDeJoueursDialog({required this.titre, required this.choix});

  @override
  State<_NombreDeJoueursDialog> createState() => _NombreDeJoueursDialogState();
}

class _NombreDeJoueursDialogState extends State<_NombreDeJoueursDialog> {
  late int _selection = widget.choix.first;

  @override
  Widget build(BuildContext context) {
    return ArcadeFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArcadeTitle(widget.titre),
            const SizedBox(height: 20),
            for (final n in widget.choix) ...[
              ArcadeOptionRow(
                label: '$n JOUEURS',
                isSelected: _selection == n,
                onTap: () => setState(() => _selection = n),
              ),
              if (n != widget.choix.last) const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                ArcadeRoundButton(
                  icon: Icons.undo_rounded,
                  tooltip: 'Retour',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ArcadeActionButton(
                    label: 'SUIVANT',
                    onTap: () => Navigator.pop(context, _selection),
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

class _ChoixCouleurDialog extends StatefulWidget {
  const _ChoixCouleurDialog();

  @override
  State<_ChoixCouleurDialog> createState() => _ChoixCouleurDialogState();
}

class _ChoixCouleurDialogState extends State<_ChoixCouleurDialog> {
  PlayerColor _selection = PlayerColor.blue;

  @override
  Widget build(BuildContext context) {
    return ArcadeFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ArcadeTitle('CHOISIS TA COULEUR'),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final couleur in PlayerColor.values)
                  ColorPin(color: couleur, raised: _selection == couleur),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final couleur in PlayerColor.values)
                  ColorRingChoice(
                    color: couleur,
                    selected: _selection == couleur,
                    onTap: () => setState(() => _selection = couleur),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              // La couleur et l'animal qui va avec : c'est la figurine que la
              // personne verra sur le plateau.
              '${speciesLabel(speciesFor(_selection)).toUpperCase()} · '
              '${_selection.name.toUpperCase()}',
              style: AppText.display(size: 17, color: AppColors.goldLight),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ArcadeRoundButton(
                  icon: Icons.undo_rounded,
                  tooltip: 'Retour',
                  onTap: () => Navigator.pop(context, _EtapeAction.retour),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ArcadeActionButton(
                    label: 'JOUER',
                    onTap: () => Navigator.pop(context, _selection),
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
