import 'package:flutter/foundation.dart';

import '../components/player.dart';
import '../data/balance.dart';
import '../data/blessing.dart';
import '../data/boss_boon.dart';
import '../data/curse.dart';
import '../data/game_modifier.dart';
import '../data/player_stats.dart';
import '../data/relic.dart';
import '../data/room_type.dart';
import '../systems/meta_progress.dart';
import '../systems/synergy_resolver.dart';

class GameState extends ChangeNotifier {
  final PlayerStats stats = PlayerStats();
  final List<Blessing> blessings = [];
  final List<Curse> curses = [];
  final List<BossBoon> bossBoons = [];
  Relic? relic;

  List<GameModifier> get modifiers => [
    ?relic,
    ...blessings,
    ...curses,
    ...bossBoons,
  ];

  int maxHp = 100;
  int hp = 100;
  int kills = 0;
  int essence = 0;
  int floor = 1;
  int maxFloorReached = 1;
  int room = 1;
  RoomType roomType = RoomType.normal;
  bool isBossRoom = false;
  bool isRoomCleared = false;
  bool isGameOver = false;
  int lastSigilsEarned = 0;
  bool lastRunNewBestScore = false;
  bool lastRunNewBestFloor = false;
  double killEssenceMultiplier = 1;
  double bossFavorEssenceMultiplier = 1.5;
  int? bossFavorFloor;
  bool healingBlocked = false;
  bool firstPactCurseNegated = false;
  bool revivalUnlocked = false;
  bool revivalUsed = false;
  int _startingHpBonus = 0;
  double _metaHpMultiplier = 1;
  double _metaAttackMultiplier = 1;
  double _metaMoveMultiplier = 1;
  bool _metaBonusesApplied = false;
  BuildReport buildReport = const BuildReport(
    synergies: [],
    conflicts: [],
    scoreMultiplier: 1,
  );

  int get curseBonus => curses.length * Balance.curseScoreBonus;

  int get score {
    final baseScore =
        kills * 100 + maxFloorReached * 420 + room * 40 + curseBonus;
    return (baseScore * buildReport.scoreMultiplier).round();
  }

  double get hpRatio => maxHp == 0 ? 0 : hp / maxHp;

  bool get bossFavorActive => bossFavorFloor == floor;

  bool get revivalAvailable => revivalUnlocked && !revivalUsed;

  void takeDamage(int amount, {bool playerMoving = true}) {
    if (isGameOver || amount <= 0) {
      return;
    }

    final conflictDamageMultiplier =
        buildReport.conflicts.any((conflict) => conflict.id == 'bleeding_debt')
        ? 1.15
        : 1.0;
    final stationaryMultiplier = playerMoving
        ? 1.0
        : stats.stationaryDamageTakenMultiplier;
    final scaledDamage =
        (amount *
                stats.damageTakenMultiplier *
                conflictDamageMultiplier *
                stationaryMultiplier)
            .ceil();
    hp = (hp - scaledDamage).clamp(0, maxHp);
    if (hp == 0) {
      isGameOver = true;
      debugPrint('Game Over: player died');
    }
    notifyListeners();
  }

  void addKill() {
    kills += 1;
    final bossFavorMultiplier = bossFavorActive
        ? bossFavorEssenceMultiplier
        : 1.0;
    addEssence(
      (Balance.baseKillEssence * killEssenceMultiplier * bossFavorMultiplier)
          .round(),
      notify: false,
    );
    if (stats.healOnKill > 0) {
      heal(stats.healOnKill);
      return;
    }
    notifyListeners();
  }

  void addEssence(int amount, {bool notify = true}) {
    if (amount <= 0) {
      return;
    }

    essence += amount;
    if (notify) {
      notifyListeners();
    }
  }

  bool spendEssence(int amount) {
    if (amount <= 0) {
      return true;
    }
    if (essence < amount) {
      return false;
    }

    essence -= amount;
    notifyListeners();
    return true;
  }

  void heal(int amount) {
    if (amount <= 0 || isGameOver || healingBlocked) {
      return;
    }

    final scaledHeal = (amount * stats.healingMultiplier).ceil();
    hp = (hp + scaledHeal).clamp(0, maxHp);
    notifyListeners();
  }

  void setRoom(int value) {
    room = value;
    notifyListeners();
  }

  void setRoomType(RoomType value) {
    roomType = value;
    notifyListeners();
  }

  void setFloor(int value) {
    floor = value;
    if (value > maxFloorReached) {
      maxFloorReached = value;
    }
    notifyListeners();
  }

  void setBossRoom(bool value) {
    isBossRoom = value;
    notifyListeners();
  }

  void activateBossFavor() {
    bossFavorFloor = floor;
    notifyListeners();
  }

  void clearBossFavor() {
    if (bossFavorFloor == null) {
      return;
    }

    bossFavorFloor = null;
    notifyListeners();
  }

  void setRoomCleared(bool value) {
    isRoomCleared = value;
    notifyListeners();
  }

  void updateBuildReport(BuildReport report) {
    buildReport = report;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void applyMetaBonuses(MetaProgress metaProgress) {
    if (_metaBonusesApplied) {
      return;
    }

    final hpBonus = metaProgress.startingHpBonus;
    _startingHpBonus = hpBonus;
    _metaHpMultiplier = metaProgress.metaHpMultiplier;
    _metaAttackMultiplier = metaProgress.metaAttackMultiplier;
    _metaMoveMultiplier = metaProgress.metaMoveMultiplier;
    if (hpBonus > 0) {
      maxHp += hpBonus;
      hp += hpBonus;
      stats.maxHp += hpBonus;
    }
    final essenceBonus = metaProgress.startingEssenceBonus;
    if (essenceBonus > 0) {
      essence += essenceBonus;
    }
    revivalUnlocked = metaProgress.revivalUnlocked;
    _metaBonusesApplied = true;
    notifyListeners();
  }

  bool reviveAtHalfHp() {
    if (!revivalAvailable || !isGameOver) {
      return false;
    }

    revivalUsed = true;
    isGameOver = false;
    hp = (maxHp / 2).ceil().clamp(1, maxHp);
    notifyListeners();
    return true;
  }

  void setMetaReward(RunMetaReward reward) {
    lastSigilsEarned = reward.sigilsEarned;
    lastRunNewBestScore = reward.isNewBestScore;
    lastRunNewBestFloor = reward.isNewBestFloor;
    notifyListeners();
  }

  void addPact(Blessing blessing, Curse curse, Player player) {
    blessings.add(blessing);
    if (firstPactCurseNegated) {
      firstPactCurseNegated = false;
      debugPrint('Relic negated pact curse: ${curse.name}');
    } else {
      curses.add(curse);
    }
    rebuildStats(player);

    debugPrint(
      'Pact: ${blessing.name} + ${curse.name} | '
      'HP $hp/$maxHp, damage ${stats.attackDamage.toStringAsFixed(1)}, '
      'attackSpeed ${stats.attackSpeed.toStringAsFixed(2)}, '
      'moveSpeed ${stats.moveSpeed.toStringAsFixed(1)}',
    );
    notifyListeners();
  }

  void addBlessing(Blessing blessing, Player player) {
    blessings.add(blessing);
    rebuildStats(player);
    notifyListeners();
  }

  void addBossBoon(BossBoon boon, Player player) {
    bossBoons.add(boon);
    rebuildStats(player);
    notifyListeners();
  }

  bool removeCurse(Curse curse, Player player) {
    final removed = curses.remove(curse);
    if (!removed) {
      return false;
    }

    rebuildStats(player);
    notifyListeners();
    return true;
  }

  void addCurse(Curse curse, Player player) {
    curses.add(curse);
    rebuildStats(player);
    notifyListeners();
  }

  void selectRelic(Relic selectedRelic, Player player) {
    relic = selectedRelic;
    if (selectedRelic.id == 'contract_seal') {
      firstPactCurseNegated = true;
    }
    rebuildStats(player);
    notifyListeners();
  }

  void rebuildStats(Player player) {
    final hpRatioBefore = hpRatio.clamp(0.0, 1.0);
    killEssenceMultiplier = 1;
    healingBlocked = false;
    stats.reset();
    final ctx = RunContext(
      player: player,
      gameState: this,
      modifiers: modifiers,
    );
    for (final modifier in modifiers) {
      modifier.onAcquire(ctx);
    }
    stats.maxHp *= _metaHpMultiplier;
    stats.attackDamage *= _metaAttackMultiplier;
    stats.moveSpeed *= _metaMoveMultiplier;
    stats.maxHp += _startingHpBonus;

    final oldMaxHp = maxHp;
    maxHp = stats.maxHp.round().clamp(1, 999);
    if (maxHp < oldMaxHp) {
      hp = hp.clamp(1, maxHp);
    } else {
      hp = (maxHp * hpRatioBefore).round().clamp(1, maxHp);
    }
  }
}
