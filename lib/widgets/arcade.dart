import 'package:flutter/material.dart';
import '../models/player_color.dart';
import '../theme/app_theme.dart';
import 'pawn_figures.dart';

/// Les briques du style « arcade » : cadre bleu à liseré doré, gros boutons,
/// pastilles de couleur.
///
/// Elles vivaient dans `main_menu_screen.dart`, en privé, ce qui laissait les
/// autres dialogues du jeu en style Material par défaut. Sorties ici, elles
/// servent partout et le jeu n'a plus qu'une seule allure.

/// Le cadre bleu à liseré doré, autour du contenu d'un dialogue.
class ArcadeFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ArcadeFrame({super.key, required this.child, this.maxWidth = 420});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: goldFrame(
            gradient: const LinearGradient(
              colors: [AppColors.frameTop, AppColors.frameBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            radius: 12,
            borderWidth: 2.2,
            glow: 16,
          ),
          // Sans ce Material, les `Ink` des boutons se peignent sur celui du
          // Dialog, donc sous le cadre bleu : les boutons apparaissaient nus.
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// Le titre d'un dialogue arcade.
class ArcadeTitle extends StatelessWidget {
  final String text;

  const ArcadeTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.display(
            size: 24, color: AppColors.goldLight, letterSpacing: 1.1),
      );
}

/// Une ligne à cocher : la grosse pastille ronde et son libellé.
class ArcadeOptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ArcadeOptionRow({
    super.key,
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
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.gold
                    : Colors.black.withOpacity(0.22),
                border: Border.all(color: AppColors.gold, width: 3),
                // Le halo seulement sur le choix retenu : une ombre posee sur
                // un cercle transparent se voyait au travers, en disque gris.
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.65),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : const [],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.frameTop, size: 32)
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: AppText.display(size: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le gros bouton d'action bleu à liseré doré.
class ArcadeActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ArcadeActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 58,
        decoration: goldFrame(
          gradient: const LinearGradient(
            colors: [AppColors.buttonTop, AppColors.buttonBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(child: Text(label, style: AppText.display(size: 23))),
      ),
    );
  }
}

/// Le bouton rond, pour revenir en arrière.
class ArcadeRoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ArcadeRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(29),
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D99FF), AppColors.buttonBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.45),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.goldLight, size: 32),
        ),
      ),
    );
  }
}

/// Le pion planté au-dessus d'un choix de couleur : l'animal de cette
/// couleur, celui que la personne verra sur le plateau.
class ColorPin extends StatelessWidget {
  final PlayerColor color;
  final bool raised;

  const ColorPin({super.key, required this.color, this.raised = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      offset: Offset(0, raised ? -0.14 : 0),
      child: AnimalFigure(color: color, size: 56),
    );
  }
}

/// L'anneau de sélection d'une couleur.
class ColorRingChoice extends StatelessWidget {
  final PlayerColor color;
  final bool selected;
  final VoidCallback onTap;

  const ColorRingChoice({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: color.name,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? const Color(0xFF46C7FF)
                : Colors.black.withOpacity(0.22),
            border: Border.all(color: color.color, width: 5),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.color.withOpacity(0.55),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
              : null,
        ),
      ),
    );
  }
}
