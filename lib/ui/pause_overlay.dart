import 'package:flutter/material.dart';

import '../data/game_modifier.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import 'localized_game_text.dart';

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
    final loc = LocalizationService.instance;
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
                      Expanded(
                        child: Text(
                          loc.tr('ui.pause.title'),
                          style: const TextStyle(
                            color: Color(0xFFD7B84F),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: loc.tr('ui.action.resume'),
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
                                  title: loc.tr('ui.section.stats'),
                                  color: const Color(0xFFD7B84F),
                                  children: [
                                    _StatRow(
                                      loc.tr('ui.stat.hp'),
                                      '${state.hp}/${state.maxHp}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.max_hp'),
                                      stats.maxHp.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.move_speed'),
                                      stats.moveSpeed.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.attack_damage'),
                                      stats.attackDamage.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.attack_speed'),
                                      stats.attackSpeed.toStringAsFixed(2),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.dash_distance'),
                                      stats.dashDistance.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.dash_cooldown'),
                                      '${stats.dashCooldown.toStringAsFixed(2)}s',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.projectile_speed'),
                                      stats.projectileSpeed.toStringAsFixed(0),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.projectile_size'),
                                      stats.projectileRadius.toStringAsFixed(1),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.critical'),
                                      '${(stats.criticalChance * 100).round()}%',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.healing'),
                                      '${(stats.healingMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.damage_taken'),
                                      '${(stats.damageTakenMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.enemy_hp'),
                                      '${(stats.enemyHealthMultiplier * 100).round()}%',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.heal_on_kill'),
                                      '${stats.healOnKill}',
                                    ),
                                  ],
                                ),
                                _Section(
                                  title: loc.tr('ui.section.run'),
                                  color: const Color(0xFF8FA1C7),
                                  children: [
                                    _StatRow(
                                      loc.tr('ui.stat.current_floor'),
                                      '${state.floor}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.highest_floor'),
                                      '${state.maxFloorReached}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.room_visits'),
                                      '${state.room}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.room_type'),
                                      localizedRoomType(state.roomType),
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.kills'),
                                      '${state.kills}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.essence'),
                                      '${state.essence}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.sigils'),
                                      '${game.metaProgress.sigils}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.score'),
                                      '${state.score}',
                                    ),
                                    _StatRow(
                                      loc.tr('ui.stat.elapsed'),
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
                                    title: loc.tr('ui.section.relic'),
                                    color: const Color(0xFFD7B84F),
                                    children: [
                                      _ModifierCard(
                                        name: localizedModifierName(
                                          state.relic!,
                                        ),
                                        description:
                                            localizedModifierDescription(
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
                                      _ModifierCard(
                                        name: stack.displayName,
                                        description:
                                            localizedModifierDescription(
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
                                      _ModifierCard(
                                        name: stack.displayName,
                                        description:
                                            localizedModifierDescription(
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
                                      _ModifierCard(
                                        name: stack.displayName,
                                        description:
                                            localizedModifierDescription(
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
                                    for (final synergy
                                        in state.buildReport.synergies)
                                      _InfoCard(
                                        name: localizedSynergyName(synergy),
                                        description:
                                            localizedSynergyDescription(
                                              synergy,
                                            ),
                                        color: const Color(0xFFD7B84F),
                                      ),
                                  ],
                                ),
                                _Section(
                                  title:
                                      '${loc.tr('ui.section.conflicts')} x${state.buildReport.scoreMultiplier.toStringAsFixed(2)} ${loc.tr('ui.stat.score')}',
                                  color: const Color(0xFFFF5A76),
                                  emptyText: loc.tr('ui.empty.conflicts'),
                                  children: [
                                    for (final conflict
                                        in state.buildReport.conflicts)
                                      _InfoCard(
                                        name:
                                            '${localizedConflictName(conflict)} +${(conflict.scoreMultiplierBonus * 100).round()}%',
                                        description:
                                            localizedConflictDescription(
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
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 250,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _Section(
                                  title: loc.tr('ui.section.settings'),
                                  color: const Color(0xFFD7B84F),
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            loc.tr('ui.settings.language'),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        DropdownButton<AppLocale>(
                                          value: loc.locale,
                                          dropdownColor: const Color(
                                            0xFF12141C,
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: AppLocale.en,
                                              child: Text(
                                                loc.tr('ui.settings.english'),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: AppLocale.ko,
                                              child: Text(
                                                loc.tr('ui.settings.korean'),
                                              ),
                                            ),
                                          ],
                                          onChanged: (locale) {
                                            if (locale == null) {
                                              return;
                                            }
                                            loc.setLocale(locale);
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: juice.enabled,
                                      title: Text(
                                        loc.tr('ui.settings.combat_feedback'),
                                      ),
                                      activeThumbColor: const Color(0xFFD7B84F),
                                      onChanged: (value) {
                                        setState(() => juice.enabled = value);
                                      },
                                    ),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      value: juice.screenShakeEnabled,
                                      title: Text(
                                        loc.tr('ui.settings.screen_shake'),
                                      ),
                                      activeThumbColor: const Color(0xFFD7B84F),
                                      onChanged: (value) {
                                        setState(
                                          () =>
                                              juice.screenShakeEnabled = value,
                                        );
                                      },
                                    ),
                                    Text(
                                      '${loc.tr('ui.settings.bgm_volume')} ${(game.bgm.volume * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Slider(
                                      min: 0,
                                      max: 1,
                                      divisions: 10,
                                      value: game.bgm.volume,
                                      activeColor: const Color(0xFFD7B84F),
                                      onChanged: (value) {
                                        setState(
                                          () => game.bgm.setVolume(value),
                                        );
                                      },
                                    ),
                                    Text(
                                      '${loc.tr('ui.stat.shake')} ${juice.screenShakeIntensity.toStringAsFixed(1)}',
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
                                  title: loc.tr('ui.section.controls'),
                                  color: const Color(0xFF8FA1C7),
                                  children: [
                                    _HelpText(loc.tr('ui.help.move')),
                                    _HelpText(loc.tr('ui.help.dash')),
                                    _HelpText(loc.tr('ui.help.shoot')),
                                    _HelpText(loc.tr('ui.help.build')),
                                    _HelpText(loc.tr('ui.help.pause')),
                                    _HelpText(loc.tr('ui.help.debug_upstairs')),
                                  ],
                                ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFD7B84F),
                                    side: const BorderSide(
                                      color: Color(0xFFD7B84F),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: game.openCodex,
                                  child: Text(
                                    loc.tr('ui.title.codex'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                  child: Text(
                                    loc.tr('ui.action.resume'),
                                    style: const TextStyle(
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
                                  child: Text(
                                    loc.tr('ui.action.abandon'),
                                    style: const TextStyle(
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
                  emptyText ??
                      LocalizationService.instance.tr('ui.empty.default'),
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
      message: '$description\nTags: ${tags.map(localizedTag).join(', ')}',
      child: _InfoCard(
        name: name,
        description: description,
        color: color,
        footer: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tag in tags)
              _TagChip(label: localizedTag(tag), color: color),
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
