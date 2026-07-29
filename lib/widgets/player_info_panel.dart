import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/player_color.dart';

class PlayerInfoPanel extends StatelessWidget {
  final Player player;
  final bool isActive;

  const PlayerInfoPanel(
      {super.key, required this.player, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final c = player.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2B5F), Color(0xFF101A40)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? c.color : c.color.withOpacity(0.35),
          width: isActive ? 2.5 : 1.5,
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
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      c.lightColor,
                      c.color.withOpacity(0.6),
                    ]),
                    border: Border.all(color: c.color, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: c.color.withOpacity(0.35),
                          blurRadius: 6,
                          spreadRadius: 0.5),
                    ],
                  ),
                  child: Icon(Icons.location_on_rounded,
                      size: 30, color: c.darkColor),
                ),
                if (isActive)
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0E1A40), width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),

            // ── Nom & badge ──────────────────────────────────────────────
            Text(
              c.name,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: player.type == PlayerType.computer
                    ? Colors.orange.withOpacity(0.25)
                    : Colors.green.withOpacity(0.25),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                player.type == PlayerType.computer ? 'IA' : 'Vous',
                style: TextStyle(
                    color: player.type == PlayerType.computer
                        ? Colors.orange
                        : Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 5),

            // ── Monnaie ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on,
                      size: 11, color: Color(0xFFFFD700)),
                  const SizedBox(width: 3),
                  Text(
                    _formatCoins(player.coins),
                    style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // ── Pions rentrés ────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                final atHome = i < player.pawnsAtHome.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Icon(
                    atHome ? Icons.circle : Icons.circle_outlined,
                    size: 7,
                    color: atHome ? c.color : Colors.white24,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000) {
      return '${(coins / 1000).toStringAsFixed(1)}k';
    }
    return '$coins';
  }
}

