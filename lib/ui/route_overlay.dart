import 'package:flutter/material.dart';

import '../data/room_type.dart';
import '../game/cursebound_game.dart';

class RouteOverlay extends StatelessWidget {
  const RouteOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final choices = game.roomManager.nextRoomChoices;

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Your Path',
                  style: TextStyle(
                    color: Color(0xFFD7B84F),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The next room changes your risk, reward, and recovery window.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final choice in choices)
                      _RouteCard(
                        type: choice,
                        onPressed: () => game.chooseRoute(choice),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.type, required this.onPressed});

  final RoomType type;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _colorFor(type).withValues(alpha: 0.18),
          foregroundColor: _colorFor(type),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _colorFor(type)),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.icon,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              type.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(RoomType type) {
    return switch (type) {
      RoomType.start => const Color(0xFF8FA1C7),
      RoomType.normal => const Color(0xFFEDEDED),
      RoomType.treasure => const Color(0xFFD7B84F),
      RoomType.miniboss => const Color(0xFFD7B84F),
      RoomType.elite => const Color(0xFFFF5A76),
      RoomType.challenge => const Color(0xFFB11238),
      RoomType.merchant => const Color(0xFF8FA1C7),
      RoomType.offering => const Color(0xFFD7B84F),
      RoomType.upstairs => const Color(0xFF8FA1C7),
      RoomType.memory => const Color(0xFF8FA1C7),
      RoomType.boss => const Color(0xFFD7B84F),
    };
  }
}
