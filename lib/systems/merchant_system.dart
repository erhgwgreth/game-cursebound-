import 'dart:math';

import '../data/balance.dart';
import '../data/blessing.dart';
import '../data/curse.dart';

class MerchantOffer {
  const MerchantOffer({required this.blessing, required this.price});

  final Blessing blessing;
  final int price;
}

class MerchantSystem {
  MerchantSystem({Random? random}) : _random = random ?? Random();

  final Random _random;
  Set<String>? unlockedBlessingIds;
  Set<String>? unlockedCurseIds;
  final List<String> loreLines = const [
    'The first pilgrim paid with his name. The stone still remembers it.',
    'A curse removed is never destroyed. It seeps into the floor.',
    'The gold light is not mercy. It is appetite.',
    'The old contracts are carved beneath the ash.',
    'The temple does not punish greed. It sanctifies it.',
  ];

  late MerchantOffer blessingOffer;
  late Blessing deepBlessing;
  late Curse deepCurse;
  late String loreLine;
  bool blessingOfferSold = false;
  bool deeperPactSold = false;

  void roll() {
    final blessings =
        blessingTable
            .where(
              (blessing) =>
                  unlockedBlessingIds == null ||
                  unlockedBlessingIds!.contains(blessing.id),
            )
            .toList()
          ..shuffle(_random);
    final curses =
        curseTable
            .where(
              (curse) =>
                  unlockedCurseIds == null ||
                  unlockedCurseIds!.contains(curse.id),
            )
            .toList()
          ..shuffle(_random);

    blessingOffer = MerchantOffer(
      blessing: blessings.first,
      price: Balance.merchantBlessingCost,
    );
    deepBlessing = blessings.length > 1 ? blessings[1] : blessings.first;
    deepCurse = curses.first;
    loreLine = loreLines[_random.nextInt(loreLines.length)];
    blessingOfferSold = false;
    deeperPactSold = false;
  }

  void markBlessingSold() {
    blessingOfferSold = true;
  }

  void markDeeperPactSold() {
    deeperPactSold = true;
  }
}
