import 'package:flutter/material.dart';

import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';

class InscriptionOverlay extends StatelessWidget {
  const InscriptionOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService.instance;
    final fragment = game.currentInscriptionFragment;

    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF120C10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFB11238), width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.tr('ui.inscription.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD7B84F),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    fragment == null ? '' : loc.tr(fragment.textKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7B84F),
                      foregroundColor: const Color(0xFF12100A),
                    ),
                    onPressed: game.closeSinInscription,
                    child: Text(
                      loc.tr('ui.common.close'),
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
