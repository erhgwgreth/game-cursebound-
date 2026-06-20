import '../data/blessing.dart';
import '../data/curse.dart';
import '../data/game_modifier.dart';

class BuildSynergy {
  const BuildSynergy({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

class BuildConflict {
  const BuildConflict({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreMultiplierBonus,
  });

  final String id;
  final String name;
  final String description;
  final double scoreMultiplierBonus;
}

class BuildReport {
  const BuildReport({
    required this.synergies,
    required this.conflicts,
    required this.scoreMultiplier,
  });

  final List<BuildSynergy> synergies;
  final List<BuildConflict> conflicts;
  final double scoreMultiplier;

  bool get hasGlassCannon => synergies.any((s) => s.id == 'glass_cannon');

  bool get hasRushSlayer => synergies.any((s) => s.id == 'rush_slayer');

  bool get hasFireChain => synergies.any((s) => s.id == 'fire_chain');

  bool get hasReapersDeal => synergies.any((s) => s.id == 'reapers_deal');
}

class SynergyResolver {
  BuildReport evaluate(List<GameModifier> modifiers) {
    final synergies = <BuildSynergy>[];
    final conflicts = <BuildConflict>[];

    final blessings = modifiers.whereType<Blessing>().toList();
    final curses = modifiers.whereType<Curse>().toList();

    final hasLowHpBlessing = blessings.any(
      (m) => m.tags.contains(EffectTag.lowHp),
    );
    final hasHealthCurse = curses.any((m) => m.tags.contains(EffectTag.health));
    if (hasLowHpBlessing && hasHealthCurse) {
      synergies.add(
        const BuildSynergy(
          id: 'glass_cannon',
          name: 'Glass Cannon',
          description: 'Lower HP increases attack damage.',
        ),
      );
    }

    final hasMovementBlessing = blessings.any(
      (m) => m.tags.contains(EffectTag.movement),
    );
    final hasMovementRiskCurse = curses.any(
      (m) =>
          m.tags.contains(EffectTag.movement) &&
          m.tags.contains(EffectTag.risk),
    );
    if (hasMovementBlessing && hasMovementRiskCurse) {
      synergies.add(
        const BuildSynergy(
          id: 'rush_slayer',
          name: 'Rush Slayer',
          description: 'Moving boosts attack damage and speed.',
        ),
      );
    }

    final hasFire = modifiers.any((m) => m.tags.contains(EffectTag.fire));
    final hasProjectile = modifiers.any(
      (m) => m.tags.contains(EffectTag.projectile),
    );
    if (hasFire && hasProjectile) {
      synergies.add(
        const BuildSynergy(
          id: 'fire_chain',
          name: 'Fire Chain',
          description: 'Projectiles leave damaging fire patches.',
        ),
      );
    }

    final onKillCount = modifiers
        .where((m) => m.tags.contains(EffectTag.onKill))
        .length;
    if (onKillCount >= 2) {
      synergies.add(
        const BuildSynergy(
          id: 'reapers_deal',
          name: "Reaper's Deal",
          description: 'Kills grant brief invincibility and speed.',
        ),
      );
    }

    final hasOpenWounds = curses.any((m) => m.id == 'open_wounds');
    final hasThinBlood = curses.any((m) => m.id == 'thin_blood');
    if (hasOpenWounds && hasThinBlood) {
      conflicts.add(
        const BuildConflict(
          id: 'bleeding_debt',
          name: 'Bleeding Debt',
          description: 'Healing is weak and incoming damage is harsher.',
          scoreMultiplierBonus: 0.5,
        ),
      );
    }

    final scoreMultiplier =
        1 +
        conflicts.fold<double>(
          0,
          (total, conflict) => total + conflict.scoreMultiplierBonus,
        );

    return BuildReport(
      synergies: synergies,
      conflicts: conflicts,
      scoreMultiplier: scoreMultiplier,
    );
  }
}
