import 'package:flutter/material.dart';

import '../data/boss_boon.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import 'localized_game_text.dart';

class BossBoonOverlay extends StatelessWidget {
  const BossBoonOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final boons = game.currentBossBoonChoices;
    final loc = LocalizationService.instance;

    return Material(
      color: Colors.black.withValues(alpha: 0.76),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.tr('ui.boon.title'),
                  style: TextStyle(
                    color: Color(0xFFD7B84F),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('ui.boon.subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final boon in boons)
                      _BoonCard(
                        boon: boon,
                        onChoose: () => game.chooseBossBoon(boon),
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

class _BoonCard extends StatelessWidget {
  const _BoonCard({required this.boon, required this.onChoose});

  final BossBoon boon;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD7B84F), width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LocalizationService.instance.tr('ui.boon.label'),
                style: TextStyle(
                  color: Color(0xFFD7B84F),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizedModifierName(boon),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizedModifierDescription(boon),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final tag in boon.tags)
                    _TagChip(
                      label: localizedTag(tag),
                      color: const Color(0xFFD7B84F),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD7B84F),
                  foregroundColor: const Color(0xFF12100A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: onChoose,
                child: Text(
                  LocalizationService.instance.tr('ui.boon.claim'),
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
