import 'package:flutter/material.dart';

import '../data/game_modifier.dart';
import '../data/room_type.dart';
import '../game/cursebound_game.dart';

class PauseOverlay extends StatefulWidget {
  const PauseOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final state = game.gameState;
    final stats = state.stats;
    final juice = game.juice.settings;
    final blessingStacks = _groupModifiers(state.blessings);
    final curseStacks = _groupModifiers(state.curses);

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 720),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF12141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD7B84F), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Run Details',
                          style: TextStyle(
                            color: Color(0xFFD7B84F),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Resume',
                        onPressed: game.closePauseMenu,
                        icon: const Icon(Icons.close),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 320,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Section(
                                  title: 'Stats',
                                  color: const Color(0xFFD7B84F),
                                  children: [
                                    _StatRow(
                                      'HP',
                                      '${state.hp}/${state.maxHp}',
                                    ),
                                    _StatRow(
                                      'Max HP',
                                      stats.maxHp.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      'Move Speed',
                                      stats.moveSpeed.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      'Attack Damage',
                                      stats.attackDamage.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      'Attack Speed',
                                      stats.attackSpeed.toStringAsFixed(2),
                                    ),
                                    _StatRow(
                                      'Dash Distance',
                                      stats.dashDistance.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      'Dash Cooldown',
                                      '${stats.dashCooldown.toStringAsFixed(2)}s',
                                    ),
                                    _StatRow(
                                      'Projectile Speed',
                                      stats.projectileSpeed.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      'Projectile Size',
                                      stats.projectileRadius.toStringAsFixed(1),
                                    ),
                                    _StatRow(
                                      'Critical',
                                      '${(stats.criticalChance * 100).round()}%',
                                    ),
                                    _StatRow(
                                      'Healing',
                                      '${(stats.healingMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      'Damage Taken',
                                      '${(stats.damageTakenMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      'Enemy HP',
                                      '${(stats.enemyHealthMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      'Heal On Kill',
                                      '${stats.healOnKill}',
                                    ),
                                  ],
                                ),
                                _Section(
                                  title: 'Run',
                                  color: const Color(0xFF8FA1C7),
                                  children: [
                                    _StatRow('Current Floor', '${state.floor}'),
                                    _StatRow(
                                      'Highest Floor',
                                      '${state.maxFloorReached}',
                                    ),
                                    _StatRow('Room Visits', '${state.room}'),
                                    _StatRow('Room Type', state.roomType.label),
                                    _StatRow('Kills', '${state.kills}'),
                                    _StatRow('Essence', '${state.essence}'),
                                    _StatRow(
                                      'Sigils',
                                      '${game.metaProgress.sigils}',
                                    ),
                                    _StatRow('Score', '${state.score}'),
                                    _StatRow(
                                      'Elapsed',
                                      _formatTime(game.runElapsedSeconds),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (state.relic != null)
                                  _Section(
                                    title: 'Relic',
                                    color: const Color(0xFFD7B84F),
                                    children: [
                                      _ModifierCard(
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
                                      _ModifierCard(
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
                                      _ModifierCard(
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
                                      _ModifierCard(
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
                                    for (final synergy
                                        in state.buildReport.synergies)
                                      _InfoCard(
                                        name: synergy.name,
                                        description: synergy.description,
                                        color: const Color(0xFFD7B84F),
                                      ),
                                  ],
                                ),
                                _Section(
                                  title:
                                      'Conflicts x${state.buildReport.scoreMultiplier.toStringAsFixed(2)} score',
                                  color: const Color(0xFFFF5A76),
                                  emptyText: 'No active conflicts.',
                                  children: [
                                    for (final conflict
                                        in state.buildReport.conflicts)
                                      _InfoCard(
                                        name:
                                            '${conflict.name} +${(conflict.scoreMultiplierBonus * 100).round()}%',
                                        description: conflict.description,
                                        color: const Color(0xFFFF5A76),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 250,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Section(
                                  title: 'Settings',
                                  color: const Color(0xFFD7B84F),
                                  children: [
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: juice.enabled,
                                      title: const Text('Combat feedback'),
                                      activeThumbColor: const Color(0xFFD7B84F),
                                      onChanged: (value) {
                                        setState(() => juice.enabled = value);
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: juice.screenShakeEnabled,
                                      title: const Text('Screen shake'),
                                      activeThumbColor: const Color(0xFFD7B84F),
                                      onChanged: (value) {
                                        setState(
                                          () =>
                                              juice.screenShakeEnabled = value,
                                        );
                                      },
                                    ),
                                    Text(
                                      'Shake ${juice.screenShakeIntensity.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Slider(
                                      min: 0,
                                      max: 1.5,
                                      divisions: 6,
                                      value: juice.screenShakeIntensity.clamp(
                                        0,
                                        1.5,
                                      ),
                                      activeColor: const Color(0xFFD7B84F),
                                      onChanged: juice.screenShakeEnabled
                                          ? (value) {
                                              setState(
                                                () =>
                                                    juice.screenShakeIntensity =
                                                        value,
                                              );
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                                _Section(
                                  title: 'Controls',
                                  color: const Color(0xFF8FA1C7),
                                  children: const [
                                    _HelpText('WASD / Arrow: move'),
                                    _HelpText('Space / Shift: dash'),
                                    _HelpText('Mouse click: shoot'),
                                    _HelpText('Tab / B: build summary'),
                                    _HelpText('Esc: resume / pause'),
                                    _HelpText('F8: debug warp upstairs'),
                                  ],
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFD7B84F),
                                    foregroundColor: const Color(0xFF12100A),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: game.closePauseMenu,
                                  child: const Text(
                                    'Resume',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFF5A76),
                                    side: const BorderSide(
                                      color: Color(0xFFB11238),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: game.abandonRun,
                                  child: const Text(
                                    'Abandon Run',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  String _formatTime(double seconds) {
    final totalSeconds = seconds.floor();
    final minutes = totalSeconds ~/ 60;
    final remainder = totalSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF08090D),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.42)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
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
              const SizedBox(height: 8),
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
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierCard extends StatelessWidget {
  const _ModifierCard({
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
      child: _InfoCard(
        name: name,
        description: description,
        color: color,
        footer: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tag in tags) _TagChip(label: tag.name, color: color),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.name,
    required this.description,
    required this.color,
    this.footer,
  });

  final String name;
  final String description;
  final Color color;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.58)),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 8), footer!],
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

class _HelpText extends StatelessWidget {
  const _HelpText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
