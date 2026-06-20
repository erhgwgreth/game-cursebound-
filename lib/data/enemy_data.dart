enum EnemyKind {
  charger,
  caster,
  bomber,
  warden,
  hexer,
  mirrorWraith,
  artillery,
  summoner,
  splitter,
  acolyte,
}

enum EliteModifier { none, gale, thorns, runicShield }

enum SubPattern {
  redash,
  impactShockwave,
  fanShot,
  blinkAfterCast,
  lingeringBlast,
  deathFragments,
  shieldPush,
  shieldWave,
  dualHex,
  hexField,
  movingReflect,
  counterShot,
  multiArtillery,
  trackingArtillery,
  mixedSummons,
  summonShield,
  secondSplit,
  aggressiveSplits,
  areaHeal,
  attackBlessing,
}

class EnemyAttackProfile {
  const EnemyAttackProfile({
    required this.projectileCount,
    required this.attackRadius,
    required this.telegraphTime,
    required this.burstCount,
    required this.moveSpeed,
    required this.unlockedPatterns,
  });

  final int Function(int level) projectileCount;
  final double Function(int level) attackRadius;
  final double Function(int level) telegraphTime;
  final int Function(int level) burstCount;
  final double Function(int level) moveSpeed;
  final List<SubPattern> Function(int level) unlockedPatterns;

  bool hasPattern(int level, SubPattern pattern) {
    return unlockedPatterns(level).contains(pattern);
  }
}

class EnemyProfiles {
  const EnemyProfiles._();

  static EnemyAttackProfile forKind(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.charger => charger,
      EnemyKind.caster => caster,
      EnemyKind.bomber => bomber,
      EnemyKind.warden => warden,
      EnemyKind.hexer => hexer,
      EnemyKind.mirrorWraith => mirrorWraith,
      EnemyKind.artillery => artillery,
      EnemyKind.summoner => summoner,
      EnemyKind.splitter => splitter,
      EnemyKind.acolyte => acolyte,
    };
  }

  static final EnemyAttackProfile charger = EnemyAttackProfile(
    projectileCount: (_) => 0,
    attackRadius: (level) {
      final tierBonus = (level ~/ 3) * 22;
      return (150 + tierBonus + level * 5).clamp(150, 280).toDouble();
    },
    telegraphTime: (level) {
      final tierPenalty = (level ~/ 3) * 0.035;
      return (0.72 - level * 0.018 - tierPenalty).clamp(0.32, 0.72);
    },
    burstCount: (level) => level >= 4 ? 2 : 1,
    moveSpeed: (level) => 95 + level.clamp(0, 10) * 2,
    unlockedPatterns: (level) => [
      if (level >= 4) SubPattern.redash,
      if (level >= 8) SubPattern.impactShockwave,
    ],
  );

  static final EnemyAttackProfile caster = EnemyAttackProfile(
    projectileCount: (level) {
      if (level >= 7) {
        return 5;
      }
      if (level >= 3) {
        return 3;
      }
      return 1;
    },
    attackRadius: (_) => 330,
    telegraphTime: (level) => (0.76 - level * 0.022).clamp(0.42, 0.76),
    burstCount: (level) => level >= 8 ? 2 : 1,
    moveSpeed: (level) => 90 + level.clamp(0, 10) * 2,
    unlockedPatterns: (level) => [
      if (level >= 3) SubPattern.fanShot,
      if (level >= 8) SubPattern.blinkAfterCast,
    ],
  );

  static final EnemyAttackProfile bomber = EnemyAttackProfile(
    projectileCount: (level) => level >= 8 ? 8 : 0,
    attackRadius: (level) => (104 + level * 4).clamp(104, 148).toDouble(),
    telegraphTime: (level) => (0.82 - level * 0.014).clamp(0.46, 0.82),
    burstCount: (_) => 1,
    moveSpeed: (level) => 95 + level.clamp(0, 12) * 2,
    unlockedPatterns: (level) => [
      if (level >= 4) SubPattern.lingeringBlast,
      if (level >= 8) SubPattern.deathFragments,
    ],
  );

  static final EnemyAttackProfile warden = EnemyAttackProfile(
    projectileCount: (level) => level >= 8 ? 3 : 0,
    attackRadius: (level) => (72 + level * 2.5).clamp(72, 102),
    telegraphTime: (level) => (0.7 - level * 0.02).clamp(0.42, 0.7),
    burstCount: (_) => 1,
    moveSpeed: (level) => 82 + level.clamp(0, 8) * 2,
    unlockedPatterns: (level) => [
      if (level >= 4) SubPattern.shieldPush,
      if (level >= 8) SubPattern.shieldWave,
    ],
  );

  static final EnemyAttackProfile hexer = EnemyAttackProfile(
    projectileCount: (_) => 0,
    attackRadius: (level) => (104 + level * 4).clamp(104, 156).toDouble(),
    telegraphTime: (level) => (0.78 - level * 0.018).clamp(0.42, 0.78),
    burstCount: (_) => 1,
    moveSpeed: (level) => 82 + level.clamp(0, 10) * 1.5,
    unlockedPatterns: (level) => [
      if (level >= 5) SubPattern.dualHex,
      if (level >= 9) SubPattern.hexField,
    ],
  );

  static final EnemyAttackProfile mirrorWraith = EnemyAttackProfile(
    projectileCount: (level) {
      if (level >= 13) {
        return 5;
      }
      if (level >= 9) {
        return 3;
      }
      return 1;
    },
    attackRadius: (level) => (84 + level * 3).clamp(84, 126).toDouble(),
    telegraphTime: (level) => (0.66 - level * 0.015).clamp(0.38, 0.66),
    burstCount: (_) => 1,
    moveSpeed: (level) => 104 + level.clamp(0, 10) * 2,
    unlockedPatterns: (level) => [
      if (level >= 7) SubPattern.movingReflect,
      if (level >= 9) SubPattern.counterShot,
    ],
  );

  static final EnemyAttackProfile artillery = EnemyAttackProfile(
    projectileCount: (level) {
      if (level >= 9) {
        return 4;
      }
      if (level >= 6) {
        return 3;
      }
      return 1;
    },
    attackRadius: (level) => (70 + level * 4).clamp(70, 120).toDouble(),
    telegraphTime: (level) => (0.92 - level * 0.024).clamp(0.48, 0.92),
    burstCount: (level) => level >= 9 ? 2 : 1,
    moveSpeed: (level) => 72 + level.clamp(0, 8) * 1.5,
    unlockedPatterns: (level) => [
      if (level >= 6) SubPattern.multiArtillery,
      if (level >= 9) SubPattern.trackingArtillery,
    ],
  );

  static final EnemyAttackProfile summoner = EnemyAttackProfile(
    projectileCount: (_) => 0,
    attackRadius: (_) => 420,
    telegraphTime: (level) => (0.86 - level * 0.018).clamp(0.46, 0.86),
    burstCount: (_) => 1,
    moveSpeed: (level) => 76 + level.clamp(0, 8) * 1.5,
    unlockedPatterns: (level) => [
      if (level >= 7) SubPattern.mixedSummons,
      if (level >= 10) SubPattern.summonShield,
    ],
  );

  static final EnemyAttackProfile splitter = EnemyAttackProfile(
    projectileCount: (_) => 0,
    attackRadius: (level) => (68 + level * 2.5).clamp(68, 108).toDouble(),
    telegraphTime: (level) => (0.62 - level * 0.014).clamp(0.36, 0.62),
    burstCount: (_) => 1,
    moveSpeed: (level) => 102 + level.clamp(0, 12) * 2,
    unlockedPatterns: (level) => [
      if (level >= 13) SubPattern.secondSplit,
      if (level >= 16) SubPattern.aggressiveSplits,
    ],
  );

  static final EnemyAttackProfile acolyte = EnemyAttackProfile(
    projectileCount: (_) => 0,
    attackRadius: (level) => (150 + level * 8).clamp(150, 280).toDouble(),
    telegraphTime: (level) => (0.9 - level * 0.018).clamp(0.48, 0.9),
    burstCount: (_) => 1,
    moveSpeed: (level) => 78 + level.clamp(0, 10) * 1.4,
    unlockedPatterns: (level) => [
      if (level >= 13) SubPattern.areaHeal,
      if (level >= 16) SubPattern.attackBlessing,
    ],
  );
}
