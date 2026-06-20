import 'package:flutter/material.dart';

import '../data/story_fragment.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';

enum _CodexTab { all, memories, inscriptions }

class CodexOverlay extends StatefulWidget {
  const CodexOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  State<CodexOverlay> createState() => _CodexOverlayState();
}

class _CodexOverlayState extends State<CodexOverlay> {
  _CodexTab _tab = _CodexTab.all;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.game.metaProgress,
        LocalizationService.instance,
      ]),
      builder: (context, _) {
        final loc = LocalizationService.instance;
        final revealed = widget.game.metaProgress.revealedStoryFragmentIds;
        final total = storyFragmentTable.length;
        final revealedCount = storyFragmentTable
            .where((fragment) => revealed.contains(fragment.id))
            .length;
        final revealedSin = widget.game.metaProgress.revealedStoryFragments
            .where((fragment) => fragment.kind == FragmentKind.sinInscription)
            .toList();
        final showMemories =
            _tab == _CodexTab.all || _tab == _CodexTab.memories;
        final showInscriptions =
            _tab == _CodexTab.all || _tab == _CodexTab.inscriptions;

        return Material(
          color: Colors.black.withValues(alpha: 0.84),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920, maxHeight: 700),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF12141C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD7B84F),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.tr('ui.codex.title'),
                              style: const TextStyle(
                                color: Color(0xFFD7B84F),
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: loc.tr('ui.common.close'),
                            onPressed: widget.game.closeCodex,
                            icon: const Icon(Icons.close),
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${loc.tr('ui.codex.subtitle')}  ${loc.tr('ui.codex.progress', params: {'revealed': '$revealedCount', 'total': '$total'})}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: loc.tr('ui.codex.all'),
                            selected: _tab == _CodexTab.all,
                            onTap: () => setState(() => _tab = _CodexTab.all),
                          ),
                          _FilterChip(
                            label: loc.tr('ui.codex.memories'),
                            selected: _tab == _CodexTab.memories,
                            onTap: () =>
                                setState(() => _tab = _CodexTab.memories),
                          ),
                          _FilterChip(
                            label: loc.tr('ui.codex.inscriptions'),
                            selected: _tab == _CodexTab.inscriptions,
                            onTap: () =>
                                setState(() => _tab = _CodexTab.inscriptions),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showMemories) ...[
                                _SectionTitle(loc.tr('ui.codex.memories')),
                                const SizedBox(height: 8),
                                for (final fragment in memoryFragments)
                                  _CodexEntry(
                                    title: revealed.contains(fragment.id)
                                        ? loc.tr(
                                            'ui.codex.memory_number',
                                            params: {
                                              'order': '${fragment.order}',
                                            },
                                          )
                                        : loc.tr('ui.codex.locked'),
                                    body: revealed.contains(fragment.id)
                                        ? loc.tr(fragment.textKey)
                                        : loc.tr('ui.codex.locked_desc'),
                                    locked: !revealed.contains(fragment.id),
                                  ),
                                const SizedBox(height: 18),
                              ],
                              if (showInscriptions) ...[
                                _SectionTitle(loc.tr('ui.codex.inscriptions')),
                                const SizedBox(height: 8),
                                if (revealedSin.isEmpty)
                                  _CodexEntry(
                                    title: loc.tr('ui.codex.locked'),
                                    body: loc.tr('ui.codex.no_inscriptions'),
                                    locked: true,
                                  )
                                else
                                  for (final fragment in revealedSin)
                                    _CodexEntry(
                                      title: loc.tr('ui.inscription.title'),
                                      body: loc.tr(fragment.textKey),
                                      locked: false,
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD7B84F) : const Color(0xFF08090D),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFD7B84F) : Colors.white24,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF12100A) : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD7B84F),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CodexEntry extends StatelessWidget {
  const _CodexEntry({
    required this.title,
    required this.body,
    required this.locked,
  });

  final String title;
  final String body;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.white38 : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: locked ? const Color(0xFF0B0C10) : const Color(0xFF171018),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: locked
                ? Colors.white12
                : const Color(0xFFB11238).withValues(alpha: 0.46),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: locked ? Colors.white38 : const Color(0xFFD7B84F),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
