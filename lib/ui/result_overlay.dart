import 'package:flutter/material.dart';

import '../game/cursebound_game.dart';

class ResultOverlay extends StatelessWidget {
  const ResultOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final state = game.gameState;
    final title = state.isGameOver ? 'You Died' : 'Run Abandoned';

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
                    label: 'Highest Floor',
                    value: '${state.maxFloorReached}',
                  ),
                  _ResultRow(label: 'Ended On Floor', value: '${state.floor}'),
                  _ResultRow(label: 'Room', value: '${state.room}'),
                  _ResultRow(label: 'Kills', value: '${state.kills}'),
                  _ResultRow(label: 'Curses', value: '${state.curses.length}'),
                  _ResultRow(
                    label: 'Relic',
                    value: state.relic?.name ?? 'None',
                  ),
                  _ResultRow(
                    label: 'Curse Bonus',
                    value: '+${state.curseBonus}',
                  ),
                  _ResultRow(
                    label: 'Sigils Earned',
                    value: '+${state.lastSigilsEarned}',
                  ),
                  if (state.lastRunNewBestScore)
                    const _ResultRow(label: 'Record', value: 'New Best Score'),
                  if (state.lastRunNewBestFloor)
                    const _ResultRow(label: 'Depth', value: 'New Best Floor'),
                  const Divider(height: 30, color: Color(0xFF323747)),
                  _ResultRow(
                    label: 'Score',
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
                    child: const Text(
                      'Restart',
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
