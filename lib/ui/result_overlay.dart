import 'package:flutter/material.dart';

import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import 'localized_game_text.dart';

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.gameState;
    final loc = LocalizationService.instance;
    final title = state.isGameOver
        ? loc.tr('ui.result.died')
        : loc.tr('ui.result.abandoned');

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF12141C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD7B84F), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFF5A76),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ResultRow(
                    label: loc.tr('ui.result.highest_floor'),
                    value: '${state.maxFloorReached}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.ended_floor'),
                    value: '${state.floor}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.room'),
                    value: '${state.room}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.kills'),
                    value: '${state.kills}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.curses'),
                    value: '${state.curses.length}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.relic'),
                    value: state.relic == null
                        ? loc.tr('ui.result.none')
                        : localizedModifierName(state.relic!),
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.curse_bonus'),
                    value: '+${state.curseBonus}',
                  ),
                  _ResultRow(
                    label: loc.tr('ui.result.sigils_earned'),
                    value: '+${state.lastSigilsEarned}',
                  ),
                  if (state.lastRunNewBestScore)
                    _ResultRow(
                      label: loc.tr('ui.result.record'),
                      value: loc.tr('ui.result.new_best_score'),
                    ),
                  if (state.lastRunNewBestFloor)
                    _ResultRow(
                      label: loc.tr('ui.result.depth'),
                      value: loc.tr('ui.result.new_best_floor'),
                    ),
                  const Divider(height: 30, color: Color(0xFF323747)),
                  _ResultRow(
                    label: loc.tr('ui.result.score'),
                    value: '${state.score}',
                    isLarge: true,
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7B84F),
                      foregroundColor: const Color(0xFF12100A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: game.onRestart,
                    child: Text(
                      loc.tr('ui.result.restart'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.isLarge = false,
  });

  final String label;
  final String value;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isLarge ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isLarge ? const Color(0xFFD7B84F) : Colors.white,
              fontSize: isLarge ? 24 : 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
