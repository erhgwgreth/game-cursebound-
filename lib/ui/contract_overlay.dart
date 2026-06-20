import 'package:flutter/material.dart';

import '../data/game_modifier.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import '../systems/contract_system.dart';
import '../systems/synergy_resolver.dart';
import 'localized_game_text.dart';

class ContractOverlay extends StatelessWidget {
  const ContractOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final pacts = game.currentPacts;
    final loc = LocalizationService.instance;

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.tr('ui.contract.title'),
                  style: TextStyle(
                    color: Color(0xFFD7B84F),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.tr('ui.contract.subtitle'),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final pact in pacts)
                      _PactCard(
                        game: game,
                        pact: pact,
                        onChoose: () => game.choosePact(pact),
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

class _PactCard extends StatelessWidget {
  const _PactCard({
    required this.game,
    required this.pact,
    required this.onChoose,
  });

  final CurseboundGame game;
  final Pact pact;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final currentReport = game.gameState.buildReport;
    final predictedReport = game.synergyResolver.evaluate([
      ...game.gameState.modifiers,
      pact.blessing,
      pact.curse,
    ]);
    final newSynergies = _newSynergies(currentReport, predictedReport);
    final newConflicts = _newConflicts(currentReport, predictedReport);

    return SizedBox(
      width: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD7B84F), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EffectPanel(
                label: loc.tr('ui.contract.blessing'),
                color: const Color(0xFFD7B84F),
                name: localizedModifierName(pact.blessing),
                description: localizedModifierDescription(pact.blessing),
                tags: pact.blessing.tags,
              ),
              const SizedBox(height: 12),
              _EffectPanel(
                label: loc.tr('ui.contract.curse'),
                color: const Color(0xFFB11238),
                name: localizedModifierName(pact.curse),
                description: localizedModifierDescription(pact.curse),
                tags: pact.curse.tags,
              ),
              if (newSynergies.isNotEmpty || newConflicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PreviewPanel(synergies: newSynergies, conflicts: newConflicts),
              ],
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
                child: Text(loc.tr('ui.contract.bind')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BuildSynergy> _newSynergies(BuildReport current, BuildReport predicted) {
    final currentIds = current.synergies.map((s) => s.id).toSet();
    return predicted.synergies
        .where((synergy) => !currentIds.contains(synergy.id))
        .toList();
  }

  List<BuildConflict> _newConflicts(
    BuildReport current,
    BuildReport predicted,
  ) {
    final currentIds = current.conflicts.map((c) => c.id).toSet();
    return predicted.conflicts
        .where((conflict) => !currentIds.contains(conflict.id))
        .toList();
  }
}

class _EffectPanel extends StatelessWidget {
  const _EffectPanel({
    required this.label,
    required this.color,
    required this.name,
    required this.description,
    required this.tags,
  });

  final String label;
  final Color color;
  final String name;
  final String description;
  final Set<EffectTag> tags;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final tag in tags)
                  _TagChip(label: localizedTag(tag), color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.synergies, required this.conflicts});

  final List<BuildSynergy> synergies;
  final List<BuildConflict> conflicts;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF08090D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final synergy in synergies)
              Text(
                '${loc.tr('ui.contract.preview_synergy')}: ${localizedSynergyName(synergy)}',
                style: const TextStyle(
                  color: Color(0xFFD7B84F),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            for (final conflict in conflicts)
              Text(
                '${loc.tr('ui.contract.preview_risk')}: ${localizedConflictName(conflict)} (+${(conflict.scoreMultiplierBonus * 100).round()}% ${loc.tr('ui.stat.score')})',
                style: const TextStyle(
                  color: Color(0xFFFF5A76),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
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
