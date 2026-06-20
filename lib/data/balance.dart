import 'room_type.dart';

class Balance {
  const Balance._();

  static const int baseKillEssence = 3;
  static const int curseScoreBonus = 180;

  static const int removeCurseCost = 28;
  static const int merchantBlessingCost = 26;
  static const int merchantRerollCost = 9;

  static const int startingHpUnlockBonus = 10;
  static const int startingEssenceUnlockBonus = 12;
  static const int cachedFloorRadius = 3;
  static const int maxMetaHpLevel = 5;
  static const int maxMetaAttackLevel = 5;
  static const int maxMetaMoveLevel = 4;
  static const double metaHpPerLevel = 0.03;
  static const double metaAttackPerLevel = 0.02;
  static const double metaMovePerLevel = 0.02;
  static const double baseRoomWidth = 900;
  static const double baseRoomHeight = 560;
  static const double roomScalePerFloor = 0.045;
  static const double maxRoomScale = 1.65;

  static double roomScale(int floor) {
    return (1.0 + (floor - 1).clamp(0, 99) * roomScalePerFloor).clamp(
      1.0,
      maxRoomScale,
    );
  }

  static ({double width, double height}) roomSize(int floor) {
    final scale = roomScale(floor);
    return (width: baseRoomWidth * scale, height: baseRoomHeight * scale);
  }

  static double enemyHealthScale({required int floor, required int room}) {
    return 1 + (floor - 1).clamp(0, 99) * 0.1 + (room - 1).clamp(0, 99) * 0.025;
  }

  static double enemyDamageScale({required int floor, required int room}) {
    return 1 +
        (floor - 1).clamp(0, 99) * 0.07 +
        (room - 1).clamp(0, 99) * 0.015;
  }

  static int normalEnemyCount({required int floor, required int room}) {
    return (3 + (floor ~/ 2) + (room ~/ 4)).clamp(3, 9);
  }

  static int floorRoomCount(int floor) {
    return (10 + floor).clamp(10, 24);
  }

  static int unlockedEnemyKindCount(int floor) {
    if (floor >= 14) {
      return 10;
    }
    if (floor >= 12) {
      return 9;
    }
    if (floor >= 10) {
      return 8;
    }
    if (floor >= 8) {
      return 7;
    }
    if (floor >= 6) {
      return 6;
    }
    if (floor >= 4) {
      return 5;
    }
    return 4;
  }

  static int unlockedEliteModifierCount(int floor) {
    if (floor >= 4) {
      return 3;
    }
    if (floor >= 3) {
      return 2;
    }
    if (floor >= 2) {
      return 1;
    }
    return 0;
  }

  static int eliteEnemyCount(int floor) {
    return floor >= 5 ? 3 : 2;
  }

  static double eliteHealthBonus(int floor) {
    return 1.65 + (floor - 1).clamp(0, 20) * 0.05;
  }

  static List<RoomType> specialRoomTypesForFloor(int floor) {
    final types = <RoomType>[
      RoomType.miniboss,
      RoomType.offering,
      if (floor >= 2) RoomType.elite,
      if (floor >= 3) RoomType.challenge,
      if (floor >= 4) RoomType.miniboss,
      if (floor >= 5) RoomType.elite,
      if (floor >= 7) RoomType.offering,
      if (floor >= 9) RoomType.challenge,
    ];
    return types.take((2 + floor ~/ 2).clamp(2, 8)).toList();
  }

  static int roomEssenceReward(RoomType? type, {required int curseCount}) {
    final base = switch (type) {
      RoomType.boss => 38,
      RoomType.miniboss => 30,
      RoomType.elite => 30,
      RoomType.challenge => 32,
      RoomType.treasure => 30,
      RoomType.merchant || RoomType.offering || RoomType.upstairs => 0,
      _ => 12,
    };
    final riskBonus =
        curseCount *
        switch (type) {
          RoomType.boss => 3,
          RoomType.miniboss || RoomType.elite || RoomType.challenge => 2,
          RoomType.merchant || RoomType.offering || RoomType.upstairs => 0,
          _ => 1,
        };
    return base + riskBonus;
  }

  static int sigilsForRun({
    required int floor,
    required int room,
    required int kills,
    required int curseCount,
    required bool cleared,
  }) {
    final progress = floor * 2 + room ~/ 2;
    final combat = kills ~/ 5;
    final risk = (curseCount * 1.4).round();
    final clearBonus = cleared ? 5 : 0;
    return (1 + progress + combat + risk + clearBonus).clamp(1, 26);
  }
}
