import 'dart:math';

import '../data/blessing.dart';
import '../data/curse.dart';

class Pact {
  const Pact({required this.blessing, required this.curse});

  final Blessing blessing;
  final Curse curse;
}

class ContractSystem {
  ContractSystem({Random? random}) : _random = random ?? Random();

  final Random _random;
  Set<String>? unlockedBlessingIds;
  Set<String>? unlockedCurseIds;

  List<Pact> generatePacts({int count = 3}) {
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

    return List.generate(
      count.clamp(2, 3),
      (index) => Pact(
        blessing: blessings[index % blessings.length],
        curse: curses[index % curses.length],
      ),
    );
  }
}
