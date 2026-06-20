import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/balance.dart';
import '../data/relic.dart';

class MetaUnlock {
  const MetaUnlock({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final String category;
}

enum MetaStatUpgrade {
  maxHp(
    id: 'meta_hp',
    name: 'Etched Flesh',
    description: 'Max HP +3% per level.',
    maxLevel: Balance.maxMetaHpLevel,
    baseCost: 3,
  ),
  attack(
    id: 'meta_attack',
    name: 'Sharpened Brand',
    description: 'Attack damage +2% per level.',
    maxLevel: Balance.maxMetaAttackLevel,
    baseCost: 4,
  ),
  moveSpeed(
    id: 'meta_move',
    name: 'Restless Nerves',
    description: 'Move speed +2% per level.',
    maxLevel: Balance.maxMetaMoveLevel,
    baseCost: 4,
  );

  const MetaStatUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.maxLevel,
    required this.baseCost,
  });

  final String id;
  final String name;
  final String description;
  final int maxLevel;
  final int baseCost;

  int costForLevel(int currentLevel) => baseCost + currentLevel * 2;
}

const List<MetaUnlock> metaUnlockTable = [
  MetaUnlock(
    id: 'start_hp_1',
    name: 'Etched Flesh I',
    description: 'Start each run with +10 max HP.',
    cost: 4,
    category: 'Starting Boost',
  ),
  MetaUnlock(
    id: 'start_essence_1',
    name: 'Hidden Offering I',
    description: 'Start each run with +12 Essence.',
    cost: 5,
    category: 'Starting Boost',
  ),
  MetaUnlock(
    id: 'advanced_blessings',
    name: 'Golden Heresies',
    description: 'Unlock advanced blessings in the pact pool.',
    cost: 6,
    category: 'Content',
  ),
  MetaUnlock(
    id: 'advanced_curses',
    name: 'Crimson Heresies',
    description: 'Unlock advanced curses in the pact pool.',
    cost: 6,
    category: 'Content',
  ),
  MetaUnlock(
    id: 'advanced_relics',
    name: 'Broken Reliquary',
    description: 'Unlock riskier starting relics.',
    cost: 7,
    category: 'Content',
  ),
  MetaUnlock(
    id: 'movement_relics',
    name: 'Restless Reliquary',
    description: 'Unlock movement, crit, and economy starting relics.',
    cost: 9,
    category: 'Content',
  ),
  MetaUnlock(
    id: 'deep_relics',
    name: 'Forbidden Reliquary',
    description: 'Unlock high-risk relics for boss hunting and low-HP builds.',
    cost: 11,
    category: 'Content',
  ),
  MetaUnlock(
    id: 'starting_boon',
    name: 'Stolen Authority',
    description: 'Start each run with one random Boss Boon.',
    cost: 18,
    category: 'Special Boon',
  ),
  MetaUnlock(
    id: 'one_revival',
    name: 'Last Ember',
    description: 'Revive once per run at half HP, then gain a random curse.',
    cost: 16,
    category: 'Revival',
  ),
];

class RunMetaReward {
  const RunMetaReward({
    required this.sigilsEarned,
    required this.isNewBestScore,
    required this.isNewBestFloor,
  });

  final int sigilsEarned;
  final bool isNewBestScore;
  final bool isNewBestFloor;
}

class MetaProgress extends ChangeNotifier {
  int sigils = 0;
  int bestScore = 0;
  int bestFloor = 0;
  int totalRuns = 0;
  int totalKills = 0;
  int totalCurses = 0;
  final Set<String> unlockedIds = {};
  final Map<String, int> upgradeLevels = {};

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  File get _saveFile => File('cursebound_meta_progress.json');

  bool isUnlocked(String id) => unlockedIds.contains(id);

  int levelOf(String id) => upgradeLevels[id] ?? 0;

  int get relicChoiceCount => levelOf('relic_choices').clamp(0, 3);

  double get metaHpMultiplier =>
      1 + levelOf(MetaStatUpgrade.maxHp.id) * Balance.metaHpPerLevel;

  double get metaAttackMultiplier =>
      1 + levelOf(MetaStatUpgrade.attack.id) * Balance.metaAttackPerLevel;

  double get metaMoveMultiplier =>
      1 + levelOf(MetaStatUpgrade.moveSpeed.id) * Balance.metaMovePerLevel;

  int get startingHpBonus =>
      isUnlocked('start_hp_1') ? Balance.startingHpUnlockBonus : 0;

  int get startingEssenceBonus =>
      isUnlocked('start_essence_1') ? Balance.startingEssenceUnlockBonus : 0;

  Set<String> get unlockedBlessingIds {
    final ids = <String>{
      'quick_hands',
      'sharpened_will',
      'long_step',
      'fleet_body',
      'heavy_bolts',
      'vital_vow',
      'iron_sacrament',
    };
    if (isUnlocked('advanced_blessings')) {
      ids.addAll({'hunter_pulse', 'blood_spark', 'sure_strike'});
    }
    return ids;
  }

  Set<String> get unlockedCurseIds {
    final ids = <String>{
      'frail_flesh',
      'thin_blood',
      'lead_feet',
      'heavy_lungs',
      'hardy_foes',
    };
    if (isUnlocked('advanced_curses')) {
      ids.addAll({'open_wounds', 'shaking_hands', 'brittle_bolts'});
    }
    return ids;
  }

  Set<String> get unlockedRelicIds {
    return relicTable
        .where((relic) => isUnlocked('relic:${relic.id}'))
        .map((relic) => relic.id)
        .toSet();
  }

  int relicUnlockCost(String relicId) {
    final index = relicTable.indexWhere((relic) => relic.id == relicId);
    return 4 + (index < 0 ? 0 : index ~/ 2) * 2;
  }

  int relicChoiceCost() {
    return switch (relicChoiceCount) {
      0 => 5,
      1 => 8,
      2 => 12,
      _ => 0,
    };
  }

  bool get startingBossBoonUnlocked => isUnlocked('starting_boon');

  bool get revivalUnlocked => isUnlocked('one_revival');

  Future<void> load() async {
    try {
      final file = _saveFile;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        if (json is Map<String, Object?>) {
          sigils = (json['sigils'] as num?)?.toInt() ?? 0;
          bestScore = (json['bestScore'] as num?)?.toInt() ?? 0;
          bestFloor = (json['bestFloor'] as num?)?.toInt() ?? 0;
          totalRuns = (json['totalRuns'] as num?)?.toInt() ?? 0;
          totalKills = (json['totalKills'] as num?)?.toInt() ?? 0;
          totalCurses = (json['totalCurses'] as num?)?.toInt() ?? 0;
          final unlocked = json['unlockedIds'];
          if (unlocked is List) {
            unlockedIds
              ..clear()
              ..addAll(unlocked.whereType<String>());
          }
          final levels = json['upgradeLevels'];
          if (levels is Map) {
            upgradeLevels
              ..clear()
              ..addEntries(
                levels.entries
                    .where((entry) => entry.key is String && entry.value is num)
                    .map(
                      (entry) => MapEntry(
                        entry.key as String,
                        (entry.value as num).toInt(),
                      ),
                    ),
              );
          }
        }
      }
    } on Object catch (error) {
      debugPrint('MetaProgress load failed: $error');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> unlock(String id) async {
    final stat = _statUpgradeById(id);
    if (stat != null) {
      return upgradeStat(stat);
    }
    if (id == 'relic_choices') {
      return upgradeRelicChoices();
    }
    if (id.startsWith('relic:')) {
      return unlockRelic(id.substring('relic:'.length));
    }

    MetaUnlock? unlock;
    for (final item in metaUnlockTable) {
      if (item.id == id) {
        unlock = item;
        break;
      }
    }
    if (unlock == null || unlockedIds.contains(id) || sigils < unlock.cost) {
      return false;
    }

    sigils -= unlock.cost;
    unlockedIds.add(id);
    notifyListeners();
    await save();
    return true;
  }

  Future<bool> upgradeStat(MetaStatUpgrade stat) async {
    final current = levelOf(stat.id);
    if (current >= stat.maxLevel) {
      return false;
    }
    final cost = stat.costForLevel(current);
    if (sigils < cost) {
      return false;
    }

    sigils -= cost;
    upgradeLevels[stat.id] = current + 1;
    notifyListeners();
    await save();
    return true;
  }

  Future<bool> upgradeRelicChoices() async {
    final current = relicChoiceCount;
    if (current >= 3) {
      return false;
    }
    final cost = relicChoiceCost();
    if (sigils < cost) {
      return false;
    }

    sigils -= cost;
    upgradeLevels['relic_choices'] = current + 1;
    notifyListeners();
    await save();
    return true;
  }

  Future<bool> unlockRelic(String relicId) async {
    final id = 'relic:$relicId';
    if (unlockedIds.contains(id) ||
        !relicTable.any((relic) => relic.id == relicId)) {
      return false;
    }
    final cost = relicUnlockCost(relicId);
    if (sigils < cost) {
      return false;
    }

    sigils -= cost;
    unlockedIds.add(id);
    notifyListeners();
    await save();
    return true;
  }

  RunMetaReward recordRun({
    required int floor,
    required int room,
    required int kills,
    required int curseCount,
    required int score,
    required bool cleared,
  }) {
    final sigilsEarned = _sigilsForRun(
      floor: floor,
      room: room,
      kills: kills,
      curseCount: curseCount,
      cleared: cleared,
    );
    final isNewBestScore = score > bestScore;
    final isNewBestFloor = floor > bestFloor;

    sigils += sigilsEarned;
    totalRuns += 1;
    totalKills += kills;
    totalCurses += curseCount;
    if (isNewBestScore) {
      bestScore = score;
    }
    if (isNewBestFloor) {
      bestFloor = floor;
    }

    notifyListeners();
    save();
    return RunMetaReward(
      sigilsEarned: sigilsEarned,
      isNewBestScore: isNewBestScore,
      isNewBestFloor: isNewBestFloor,
    );
  }

  void debugGrantSigils(int amount) {
    if (amount <= 0) {
      return;
    }

    sigils += amount;
    notifyListeners();
    save();
  }

  int _sigilsForRun({
    required int floor,
    required int room,
    required int kills,
    required int curseCount,
    required bool cleared,
  }) {
    return Balance.sigilsForRun(
      floor: floor,
      room: room,
      kills: kills,
      curseCount: curseCount,
      cleared: cleared,
    );
  }

  Future<void> save() async {
    try {
      final payload = const JsonEncoder.withIndent('  ').convert({
        'sigils': sigils,
        'bestScore': bestScore,
        'bestFloor': bestFloor,
        'totalRuns': totalRuns,
        'totalKills': totalKills,
        'totalCurses': totalCurses,
        'unlockedIds': unlockedIds.toList()..sort(),
        'upgradeLevels': Map<String, int>.from(upgradeLevels),
      });
      await _saveFile.writeAsString(payload);
    } on Object catch (error) {
      debugPrint('MetaProgress save failed: $error');
    }
  }

  MetaStatUpgrade? _statUpgradeById(String id) {
    for (final stat in MetaStatUpgrade.values) {
      if (stat.id == id) {
        return stat;
      }
    }
    return null;
  }
}
