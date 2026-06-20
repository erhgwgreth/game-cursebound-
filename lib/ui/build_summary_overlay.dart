import 'package:flutter/material.dart';

import '../data/game_modifier.dart';
import '../game/cursebound_game.dart';

class BuildSummaryOverlay extends StatelessWidget {
  const BuildSummaryOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.gameState;
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
                      const Expanded(
                        child: Text(
                          'Build Summary',
                          style: TextStyle(
                            color: Color(0xFFD7B84F),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
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
                        label: 'HP',
                        value: '${state.hp}/${state.maxHp}',
                      ),
                      _StatPill(
                        label: 'Damage',
                        value: state.stats.attackDamage.toStringAsFixed(0),
                      ),
                      _StatPill(
                        label: 'Attack Speed',
                        value: state.stats.attackSpeed.toStringAsFixed(2),
                      ),
                      _StatPill(
                        label: 'Move',
                        value: state.stats.moveSpeed.toStringAsFixed(0),
                      ),
                      _StatPill(label: 'Score', value: '${state.score}'),
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
                              title: 'Relic',
                              color: const Color(0xFFD7B84F),
                              children: [
                                _ModifierTile(
                                  name: state.relic!.name,
                                  description: state.relic!.description,
                                  tags: state.relic!.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                              ],
                            ),
                          _Section(
                            title: 'Boss Boons',
                            color: const Color(0xFFD7B84F),
                            emptyText: 'No boss boons yet.',
                            children: [
                              for (final stack in _groupModifiers(
                                state.bossBoons,
                              ))
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: stack.modifier.description,
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: 'Blessings',
                            color: const Color(0xFFD7B84F),
                            emptyText: 'No blessings yet.',
                            children: [
                              for (final stack in blessingStacks)
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: stack.modifier.description,
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: 'Curses',
                            color: const Color(0xFFB11238),
                            emptyText: 'No curses yet.',
                            children: [
                              for (final stack in curseStacks)
                                _ModifierTile(
                                  name: stack.displayName,
                                  description: stack.modifier.description,
                                  tags: stack.modifier.tags,
                                  color: const Color(0xFFB11238),
                                ),
                            ],
                          ),
                          _Section(
                            title: 'Synergies',
                            color: const Color(0xFFD7B84F),
                            emptyText: 'No active synergies.',
                            children: [
                              for (final synergy in state.buildReport.synergies)
                                _InfoTile(
                                  name: synergy.name,
                                  description: synergy.description,
                                  color: const Color(0xFFD7B84F),
                                ),
                            ],
                          ),
                          _Section(
                            title: 'Conflicts',
                            color: const Color(0xFFFF5A76),
                            emptyText: 'No active conflicts.',
                            children: [
                              for (final conflict
                                  in state.buildReport.conflicts)
                                _InfoTile(
                                  name:
                                      '${conflict.name} (+${(conflict.scoreMultiplierBonus * 100).round()}% score)',
                                  description: conflict.description,
                                  color: const Color(0xFFFF5A76),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tab/B: close build summary   Esc: pause',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

  String get displayName =>
      level <= 1 ? modifier.name : '${modifier.name} Lv.$level';

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
              emptyText ?? 'Empty.',
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
      message: '$description\nTags: ${tags.map((tag) => tag.name).join(', ')}',
      child: _InfoTile(
        name: name,
        description: description,
        color: color,
        trailing: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tag in tags.take(3))
              _TagChip(label: tag.name, color: color),
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
