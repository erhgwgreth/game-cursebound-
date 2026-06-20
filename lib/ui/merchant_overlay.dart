import 'package:flutter/material.dart';

import '../data/balance.dart';
import '../game/cursebound_game.dart';
import '../systems/localization_service.dart';
import 'localized_game_text.dart';

class MerchantOverlay extends StatelessWidget {
  const MerchantOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.gameState,
      builder: (context, _) {
        final state = game.gameState;
        final merchant = game.currentOfferingSystem;
        final removableCurse = state.curses.isEmpty ? null : state.curses.last;
        final blessingSold = merchant.blessingOfferSold;
        final deeperPactSold = merchant.deeperPactSold;
        final loc = LocalizationService.instance;

        return Material(
          color: Colors.black.withValues(alpha: 0.76),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.tr('ui.offering.title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD7B84F),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${merchant.loreLine}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        loc.tr(
                          'ui.offering.essence',
                          params: {'amount': '${state.essence}'},
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TradeButton(
                        title: removableCurse == null
                            ? loc.tr('ui.offering.cleanse')
                            : loc.tr(
                                'ui.offering.cleanse_named',
                                params: {
                                  'name': localizedModifierName(removableCurse),
                                },
                              ),
                        subtitle: removableCurse == null
                            ? loc.tr('ui.offering.no_curse')
                            : loc.tr(
                                'ui.offering.cleanse_cost',
                                params: {'cost': '${Balance.removeCurseCost}'},
                              ),
                        enabled:
                            removableCurse != null &&
                            state.essence >= Balance.removeCurseCost,
                        color: const Color(0xFFEDEDED),
                        onPressed: removableCurse == null
                            ? null
                            : () => game.buyRemoveCurse(removableCurse),
                      ),
                      _TradeButton(
                        title: deeperPactSold
                            ? loc.tr('ui.offering.deeper_spent')
                            : loc.tr('ui.offering.deeper'),
                        subtitle: deeperPactSold
                            ? loc.tr('ui.offering.deeper_spent_desc')
                            : loc.tr(
                                'ui.offering.deeper_desc',
                                params: {
                                  'blessing': localizedModifierName(
                                    merchant.deepBlessing,
                                  ),
                                  'curse': localizedModifierName(
                                    merchant.deepCurse,
                                  ),
                                },
                              ),
                        enabled: !deeperPactSold,
                        color: const Color(0xFFB11238),
                        onPressed: game.buyDeeperPact,
                      ),
                      _TradeButton(
                        title: blessingSold
                            ? loc.tr('ui.offering.blessing_claimed')
                            : loc.tr(
                                'ui.offering.blessing',
                                params: {
                                  'name': localizedModifierName(
                                    merchant.blessingOffer.blessing,
                                  ),
                                },
                              ),
                        subtitle: blessingSold
                            ? loc.tr('ui.offering.blessing_claimed_desc')
                            : loc.tr(
                                'ui.offering.blessing_desc',
                                params: {
                                  'description': localizedModifierDescription(
                                    merchant.blessingOffer.blessing,
                                  ),
                                  'price': '${merchant.blessingOffer.price}',
                                },
                              ),
                        enabled:
                            !blessingSold &&
                            state.essence >= merchant.blessingOffer.price,
                        color: const Color(0xFFD7B84F),
                        onPressed: game.buyMerchantBlessing,
                      ),
                      _TradeButton(
                        title: loc.tr('ui.offering.reroll'),
                        subtitle: loc.tr(
                          'ui.offering.reroll_desc',
                          params: {'cost': '${Balance.merchantRerollCost}'},
                        ),
                        enabled: state.essence >= Balance.merchantRerollCost,
                        color: const Color(0xFF8FA1C7),
                        onPressed: game.rerollMerchant,
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                        ),
                        onPressed: game.closeMerchant,
                        child: Text(loc.tr('ui.offering.step_away')),
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

class _TradeButton extends StatelessWidget {
  const _TradeButton({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.color,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FilledButton(
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: enabled
              ? color.withValues(alpha: 0.18)
              : Colors.white10,
          foregroundColor: enabled ? color : Colors.white38,
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: enabled ? color : Colors.white12),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
