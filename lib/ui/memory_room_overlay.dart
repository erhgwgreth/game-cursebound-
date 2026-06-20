import 'package:flutter/material.dart';

import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';

class MemoryRoomOverlay extends StatelessWidget {
  const MemoryRoomOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final fragment = game.currentMemoryFragment;
    final alreadyClaimed =
        game.roomManager.currentNode?.memoryRewardClaimed == true &&
        fragment == null;
    final text = fragment == null
        ? loc.tr(
            alreadyClaimed
                ? 'story.memory.already_claimed'
                : 'story.memory.complete',
          )
        : loc.tr(fragment.textKey);

    return Material(
      color: Colors.black.withValues(alpha: 0.86),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0C0D12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD7B84F), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB11238).withValues(alpha: 0.32),
                  blurRadius: 34,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.tr('ui.memory.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD7B84F),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fragment == null
                        ? loc.tr('ui.memory.subtitle_complete')
                        : loc.tr(
                            'ui.memory.subtitle',
                            params: {'order': '${fragment.order}'},
                          ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151018),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFB11238).withValues(alpha: 0.46),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.55,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                    onPressed: game.closeMemoryRoom,
                    child: Text(
                      loc.tr('ui.memory.continue'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
