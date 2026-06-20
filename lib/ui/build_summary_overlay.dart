import 'package:flutter/material.dart';

import '../data/game_modifier.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import 'localized_game_text.dart';

class BuildSummaryOverlay extends StatelessWidget {
  const BuildSummaryOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.gameState;
    final loc = LocalizationService.instance;
    final blessingStacks = _groupModifiers(state.blessings);
    final curseStacks = _groupModifiers(state.curses);

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 680),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF12141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD7B84F), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.tr('ui.summary.title'),
                          style: const TextStyle(
                            color: Color(0xFFD7B84F),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: loc.tr('ui.common.close'),
                        onPressed: game.closeBuildSummary,
                        icon: const Icon(Icons.close),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _StatPill(
                        label: loc.tr('ui.stat.hp'),
                        value: '${state.hp}/${state.maxHp}',
                      ),
                      _StatPill(
                        label: loc.tr('ui.stat.damage'),
                        value: state.stats.attackDamage.toStringAsFixed(0),
                      ),
                      _StatPill(
                        label: loc.tr('ui.stat.attack_speed'),
                        value: state.stats.attackSpeed.toStringAsFixed(2),
                      ),
                      _StatPill(
                        label: loc.tr('ui.stat.move'),
                        value: state.stats.moveSpeed.toStringAsFixed(0),
                      ),
                      _StatPill(
                        label: loc.tr('ui.stat.score'),
                        value: '${state.score}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.relic != null)
                            _Section(
                              title: loc.tr('ui.section.relic'),
                              color: const Color(0xFFD7B84F),
                              children: [
                                _ModifierTile(
                                  name: localizedModifierName(state.relic!),
                                  description: localizedModifierDescription(
                                    state.relic!,
                                  ),
                                  tags: state.relic!.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                              ],
                            ),
                          _Section(
                            title: loc.tr('ui.section.boss_boons'),
                            color: const Color(0xFFD7B84F),
                            emptyText: loc.tr('ui.empty.boss_boons'),
                            children: [
                              for (final stack in _groupModifiers(
                                state.bossBoons,
                              ))
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: localizedModifierDescription(
                                    stack.modifier,
                                  ),
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: loc.tr('ui.section.blessings'),
                            color: const Color(0xFFD7B84F),
                            emptyText: loc.tr('ui.empty.blessings'),
                            children: [
                              for (final stack in blessingStacks)
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: localizedModifierDescription(
                                    stack.modifier,
                                  ),
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: loc.tr('ui.section.curses'),
                            color: const Color(0xFFB11238),
                            emptyText: loc.tr('ui.empty.curses'),
                            children: [
                              for (final stack in curseStacks)
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: localizedModifierDescription(
                                    stack.modifier,
                                  ),
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFB11238),
                                ),
                            ],
                          ),
                          _Section(
                            title: loc.tr('ui.section.synergies'),
                            color: const Color(0xFFD7B84F),
                            emptyText: loc.tr('ui.empty.synergies'),
                            children: [
                              for (final synergy in state.buildReport.synergies)
                                _InfoTile(
                                  name: localizedSynergyName(synergy),
                                  description: localizedSynergyDescription(
                                    synergy,
                                  ),
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: loc.tr('ui.section.conflicts'),
                            color: const Color(0xFFFF5A76),
                            emptyText: loc.tr('ui.empty.conflicts'),
                            children: [
                              for (final conflict
                                  in state.buildReport.conflicts)
                                _InfoTile(
                                  name:
                                      '${localizedConflictName(conflict)} (+${(conflict.scoreMultiplierBonus * 100).round()}% ${loc.tr('ui.stat.score')})',
                                  description: localizedConflictDescription(
                                    conflict,
                                  ),
                                  color: const Color(0xFFFF5A76),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    loc.tr('ui.help.build_close'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_ModifierStack> _groupModifiers(List<GameModifier> modifiers) {
    final stacksById = <String, _ModifierStack>{};
    for (final modifier in modifiers) {
      final current = stacksById[modifier.id];
      if (current == null) {
        stacksById[modifier.id] = _ModifierStack(modifier: modifier, level: 1);
      } else {
        stacksById[modifier.id] = current.copyWith(level: current.level + 1);
      }
    }
    return stacksById.values.toList();
  }
}

class _ModifierStack {
  const _ModifierStack({required this.modifier, required this.level});

  final GameModifier modifier;
  final int level;

  String get displayName => localizedStackName(modifier, level);

  _ModifierStack copyWith({required int level}) {
    return _ModifierStack(modifier: modifier, level: level);
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.color,
    required this.children,
    this.emptyText,
  });

  final String title;
  final Color color;
  final List<Widget> children;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (children.isEmpty)
            Text(
              emptyText ?? LocalizationService.instance.tr('ui.empty.default'),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _ModifierTile extends StatelessWidget {
  const _ModifierTile({
    required this.name,
    required this.description,
    required this.tags,
    required this.color,
  });

  final String name;
  final String description;
  final Set<EffectTag> tags;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$description\nTags: ${tags.map(localizedTag).join(', ')}',
      child: _InfoTile(
        name: name,
        description: description,
        color: color,
        trailing: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tag in tags.take(3))
              _TagChip(label: localizedTag(tag), color: color),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.name,
    required this.description,
    required this.color,
    this.trailing,
  });

  final String name;
  final String description;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.62)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) ...[const SizedBox(height: 7), trailing!],
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
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF08090D),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '$label $value',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
