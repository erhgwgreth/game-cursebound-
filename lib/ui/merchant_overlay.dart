import 'package:flutter/material.dart';

import '../data/balance.dart';
import '../game/cursebound_game.dart';

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
                      const Text(
                        'Offering Altar',
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
                        'Essence: ${state.essence}',
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
                            ? 'Cleanse Curse'
                            : 'Cleanse Curse: ${removableCurse.name}',
                        subtitle: removableCurse == null
                            ? 'No curse to remove.'
                            : 'Offer ${Balance.removeCurseCost} Essence. Synergies and conflicts recalculate.',
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
                            ? 'Deeper Offering: Spent'
                            : 'Deeper Offering',
                        subtitle: deeperPactSold
                            ? 'The altar has already accepted this blood.'
                            : 'Gain ${merchant.deepBlessing.name}, but take ${merchant.deepCurse.name}. Free.',
                        enabled: !deeperPactSold,
                        color: const Color(0xFFB11238),
                        onPressed: game.buyDeeperPact,
                      ),
                      _TradeButton(
                        title: blessingSold
                            ? 'Offering Blessing: Claimed'
                            : 'Offering Blessing: ${merchant.blessingOffer.blessing.name}',
                        subtitle: blessingSold
                            ? 'This blessing has already been drawn from the altar.'
                            : '${merchant.blessingOffer.blessing.description} (${merchant.blessingOffer.price} Essence)',
                        enabled:
                            !blessingSold &&
                            state.essence >= merchant.blessingOffer.price,
                        color: const Color(0xFFD7B84F),
                        onPressed: game.buyMerchantBlessing,
                      ),
                      _TradeButton(
                        title: 'Scatter Ashes',
                        subtitle:
                            'Offer ${Balance.merchantRerollCost} Essence to redraw offerings and whispers.',
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
                        child: const Text('Step Away'),
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
