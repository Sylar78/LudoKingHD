import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/player_color.dart';
import '../theme/app_theme.dart';
import 'pawn_figures.dart';

/// La carte d'un joueur, à côté du plateau.
///
/// Elle affichait une cagnotte en pièces, tirée d'une constante par couleur et
/// jamais modifiée : quatre chiffres decoratifs. À la place, elle montre
/// maintenant ce qui se passe vraiment dans la partie : l'avancée du joueur,
/// ses pions rentrés, et son dé quand c'est son tour.
class PlayerInfoPanel extends StatelessWidget {
  final Player player;
  final bool isActive;

  /// Le dé du joueur actif. `null` pour les autres : afficher la même valeur
  /// sur les quatre cartes, comme avant, ne voulait rien dire.
  final int? diceValue;

  /// Vrai pour le joueur tenu par la personne qui regarde l'écran. En
  /// multijoueur local, tout le monde est humain : personne n'est « vous ».
  final bool isYou;

  const PlayerInfoPanel({
    super.key,
    required this.player,
    required this.isActive,
    this.diceValue,
    this.isYou = false,
  });

  static const _diceGlyph = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

  @override
  Widget build(BuildContext context) {
    final c = player.color;
    final rentres = player.pawnsAtHome.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 136,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2B5F), Color(0xFF101A40)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? c.color : c.color.withOpacity(0.32),
          width: isActive ? 2.4 : 1.4,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: c.color.withOpacity(0.45),
                  blurRadius: 14,
                  spreadRadius: 1.2,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _Avatar(color: c, isActive: isActive),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _Badge(player: player, isYou: isYou),
                    ],
                  ),
                ),
                // Le dé n'apparaît que sur la carte du joueur qui vient de le
                // lancer, ce qui dit d'un coup d'œil qui joue et avec quoi.
                if (isActive && diceValue != null)
                  Text(
                    _diceGlyph[(diceValue! - 1).clamp(0, 5)],
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        height: 1,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: player.progress),
                duration: const Duration(milliseconds: 400),
                builder: (_, valeur, __) => LinearProgressIndicator(
                  value: valeur,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation(c.color),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < player.pawns.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < rentres ? Icons.circle : Icons.circle_outlined,
                      size: 9,
                      color: i < rentres ? c.color : Colors.white24,
                    ),
                  ),
                const SizedBox(width: 5),
                Text(
                  '$rentres/${player.pawns.length}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final PlayerColor color;
  final bool isActive;

  const _Avatar({required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.lightColor.withOpacity(0.55),
                color.color.withOpacity(0.18),
              ],
            ),
            border: Border.all(color: color.color, width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.color.withOpacity(0.35),
                  blurRadius: 6,
                  spreadRadius: 0.5),
            ],
          ),
          // Le pion du joueur, le meme que sur le plateau, plutot qu'une
          // punaise generique identique pour les quatre couleurs.
          child: AnimalFigure(color: color, size: 30),
        ),
        if (isActive)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.live,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0E1A40), width: 1.5),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final Player player;
  final bool isYou;

  const _Badge({required this.player, required this.isYou});

  @override
  Widget build(BuildContext context) {
    final (String texte, Color teinte) = switch ((player.type, isYou)) {
      (PlayerType.computer, _) => ('IA', Colors.orange),
      (PlayerType.human, true) => ('Vous', Colors.greenAccent),
      (PlayerType.human, false) => ('Joueur', Colors.white70),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: teinte.withOpacity(0.20),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        texte,
        style:
            TextStyle(color: teinte, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
