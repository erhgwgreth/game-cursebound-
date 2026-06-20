import 'package:flutter/material.dart';

import '../data/relic.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import '../systems/meta_progress.dart';
import 'localized_game_text.dart';

class UnlockOverlay extends StatefulWidget {
  const UnlockOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  State<UnlockOverlay> createState() => _UnlockOverlayState();
}

class _UnlockOverlayState extends State<UnlockOverlay> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.metaProgress,
        LocalizationService.instance,
      ]),
      builder: (context, _) {
        final meta = widget.game.metaProgress;
        final loc = LocalizationService.instance;

        return Material(
          color: Colors.black.withValues(alpha: 0.86),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.game.closeUnlockScreen,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.tr('ui.unlock.title'),
                          style: TextStyle(
                            color: Color(0xFFD7B84F),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _SigilBadge(sigils: meta.sigils),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CategoryTabs(
                    selectedIndex: _tabIndex,
                    onSelected: (index) => setState(() => _tabIndex = index),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF08090D).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: _contentForTab(meta),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _contentForTab(MetaProgress meta) {
    return switch (_tabIndex) {
      0 => _StatsUnlocks(game: widget.game),
      1 => _RelicUnlocks(game: widget.game),
      2 => _SpecialBoonUnlocks(game: widget.game),
      _ => _RevivalUnlocks(game: widget.game),
    };
  }
}

class _SpecialBoonUnlocks extends StatelessWidget {
  const _SpecialBoonUnlocks({required this.game});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final meta = game.metaProgress;
    final unlock = metaUnlockTable.firstWhere(
      (item) => item.id == 'starting_boon',
    );
    final owned = meta.startingBossBoonUnlocked;
    final canBuy = !owned && meta.sigils >= unlock.cost;

    return ListView(
      children: [
        _SectionHeader(
          title: LocalizationService.instance.tr('ui.unlock.boon_title'),
          subtitle: LocalizationService.instance.tr('ui.unlock.boon_subtitle'),
        ),
        const SizedBox(height: 12),
        _UnlockTile(
          title: unlock.name,
          subtitle:
              '${unlock.description} ${LocalizationService.instance.tr('ui.unlock.boon_extra')}',
          meta: owned
              ? LocalizationService.instance.tr('ui.unlock.boon_active')
              : LocalizationService.instance.tr('ui.common.locked'),
          buttonLabel: owned
              ? LocalizationService.instance.tr('ui.common.owned')
              : '${unlock.cost}',
          canBuy: canBuy,
          onBuy: () => game.unlockMeta(unlock.id),
        ),
      ],
    );
  }
}

class _RevivalUnlocks extends StatelessWidget {
  const _RevivalUnlocks({required this.game});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final meta = game.metaProgress;
    final unlock = metaUnlockTable.firstWhere(
      (item) => item.id == 'one_revival',
    );
    final owned = meta.revivalUnlocked;
    final canBuy = !owned && meta.sigils >= unlock.cost;

    return ListView(
      children: [
        _SectionHeader(
          title: LocalizationService.instance.tr('ui.unlock.revival_title'),
          subtitle: LocalizationService.instance.tr(
            'ui.unlock.revival_subtitle',
          ),
        ),
        const SizedBox(height: 12),
        _UnlockTile(
          title: unlock.name,
          subtitle: unlock.description,
          meta: owned
              ? LocalizationService.instance.tr('ui.unlock.revival_active')
              : LocalizationService.instance.tr('ui.common.locked'),
          buttonLabel: owned
              ? LocalizationService.instance.tr('ui.common.owned')
              : '${unlock.cost}',
          canBuy: canBuy,
          onBuy: () => game.unlockMeta(unlock.id),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final labels = [
      loc.tr('ui.unlock.stats'),
      loc.tr('ui.unlock.relics'),
      loc.tr('ui.unlock.boons'),
      loc.tr('ui.unlock.revival'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i += 1)
          ChoiceChip(
            label: Text(labels[i]),
            selected: selectedIndex == i,
            selectedColor: const Color(0xFFD7B84F),
            labelStyle: TextStyle(
              color: selectedIndex == i
                  ? const Color(0xFF12100A)
                  : Colors.white,
              fontWeight: FontWeight.w900,
            ),
            onSelected: (_) => onSelected(i),
          ),
      ],
    );
  }
}

class _StatsUnlocks extends StatelessWidget {
  const _StatsUnlocks({required this.game});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final meta = game.metaProgress;
    return ListView(
      children: [
        _SectionHeader(
          title: LocalizationService.instance.tr('ui.unlock.stat_title'),
          subtitle: LocalizationService.instance.tr('ui.unlock.stat_subtitle'),
        ),
        const SizedBox(height: 12),
        for (final stat in MetaStatUpgrade.values)
          _StatCard(game: game, stat: stat, current: meta.levelOf(stat.id)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.game,
    required this.stat,
    required this.current,
  });

  final CurseboundGame game;
  final MetaStatUpgrade stat;
  final int current;

  @override
  Widget build(BuildContext context) {
    final maxed = current >= stat.maxLevel;
    final cost = stat.costForLevel(current);
    final canBuy = !maxed && game.metaProgress.sigils >= cost;

    return _UnlockTile(
      title: stat.name,
      subtitle: stat.description,
      meta:
          '${LocalizationService.instance.tr('ui.common.level')} $current/${stat.maxLevel}',
      buttonLabel: maxed ? 'MAX' : '$cost',
      canBuy: canBuy,
      onBuy: () => game.unlockMeta(stat.id),
    );
  }
}

class _RelicUnlocks extends StatelessWidget {
  const _RelicUnlocks({required this.game});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final meta = game.metaProgress;
    final choiceMaxed = meta.relicChoiceCount >= 3;
    final choiceCost = meta.relicChoiceCost();

    return ListView(
      children: [
        _SectionHeader(
          title: LocalizationService.instance.tr('ui.unlock.relic_title'),
          subtitle: LocalizationService.instance.tr('ui.unlock.relic_subtitle'),
        ),
        const SizedBox(height: 12),
        _UnlockTile(
          title: LocalizationService.instance.tr('ui.unlock.relic_choices'),
          subtitle: LocalizationService.instance.tr(
            'ui.unlock.relic_choices_desc',
            params: {'current': '${meta.relicChoiceCount}'},
          ),
          meta: '0 -> 1 -> 2 -> 3',
          buttonLabel: choiceMaxed ? 'MAX' : '$choiceCost',
          canBuy: !choiceMaxed && meta.sigils >= choiceCost,
          onBuy: () => game.unlockMeta('relic_choices'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 600
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.35,
              ),
              itemCount: relicTable.length,
              itemBuilder: (context, index) {
                final relic = relicTable[index];
                return _RelicCard(game: game, relic: relic);
              },
            );
          },
        ),
      ],
    );
  }
}

class _RelicCard extends StatelessWidget {
  const _RelicCard({required this.game, required this.relic});

  final CurseboundGame game;
  final Relic relic;

  @override
  Widget build(BuildContext context) {
    final meta = game.metaProgress;
    final unlocked = meta.unlockedRelicIds.contains(relic.id);
    final cost = meta.relicUnlockCost(relic.id);
    final canBuy = !unlocked && meta.sigils >= cost;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFF1F2117) : const Color(0xFF12141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unlocked
              ? const Color(0xFFD7B84F)
              : canBuy
              ? Colors.white54
              : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizedModifierName(relic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? const Color(0xFFD7B84F) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: canBuy
                      ? () => game.unlockMeta('relic:${relic.id}')
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD7B84F),
                    side: BorderSide(
                      color: canBuy ? const Color(0xFFD7B84F) : Colors.white24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    unlocked
                        ? LocalizationService.instance.tr('ui.common.owned')
                        : '$cost',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              localizedModifierDescription(relic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: [
                for (final tag in relic.tags)
                  _TagChip(
                    label: localizedTag(tag),
                    color: const Color(0xFFFF5A76),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockTile extends StatelessWidget {
  const _UnlockTile({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.buttonLabel,
    required this.canBuy,
    required this.onBuy,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String buttonLabel;
  final bool canBuy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12141C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: const TextStyle(
                        color: Color(0xFFD7B84F),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canBuy ? onBuy : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD7B84F),
                  foregroundColor: const Color(0xFF12100A),
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD7B84F),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SigilBadge extends StatelessWidget {
  const _SigilBadge({required this.sigils});

  final int sigils;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF21151A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD7B84F)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Sigils $sigils',
          style: const TextStyle(
            color: Color(0xFFD7B84F),
            fontWeight: FontWeight.w900,
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
        color: color.withValues(alpha: 0.14),
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
