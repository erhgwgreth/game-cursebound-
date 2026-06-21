import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart' as flame_geometry;
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/blessing.dart';
import '../data/balance.dart';
import '../data/boss_boon.dart';
import '../data/curse.dart';
import '../data/relic.dart';
import '../data/room_type.dart';
import '../data/story_fragment.dart';
import '../components/player.dart';
import '../components/projectile.dart';
import '../components/world_grid.dart';
import '../components/enemy.dart';
import '../data/game_modifier.dart';
import '../systems/audio_controller.dart';
import '../systems/bgm_manager.dart';
import '../systems/contract_system.dart';
import '../systems/localization_service.dart';
import '../systems/merchant_system.dart';
import '../systems/meta_progress.dart';
import '../systems/room_manager.dart';
import '../systems/synergy_resolver.dart';
import '../systems/juice_manager.dart';
import 'game_state.dart';

class CurseboundGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  CurseboundGame({required this.onRestart});

  static const double cameraWidth = 960;
  static const double cameraHeight = 540;

  final VoidCallback onRestart;
  final AudioController audio = AudioController();
  final BgmManager bgm = BgmManager();
  final GameState gameState = GameState();
  final ContractSystem contractSystem = ContractSystem();
  final MetaProgress metaProgress = MetaProgress();
  final SynergyResolver synergyResolver = SynergyResolver();
  final Map<String, MerchantSystem> _offeringSystems = {};
  late final JuiceManager juice;
  final math.Random _random = math.Random();

  late final Player player;
  late final RoomManager roomManager;
  List<Pact> currentPacts = [];
  List<BossBoon> currentBossBoonChoices = [];
  List<Relic> currentRelicChoices = [];
  StoryFragment? currentMemoryFragment;
  StoryFragment? currentInscriptionFragment;
  StoryFragment? nearbyInscriptionFragment;
  bool isChoosingPact = false;
  bool isChoosingBossBoon = false;
  bool isMerchantOpen = false;
  bool isMemoryRoomOpen = false;
  bool isInscriptionOpen = false;
  bool isCodexOpen = false;
  bool isRouteChoiceOpen = false;
  bool isChoosingRelic = false;
  bool isUnlockScreenOpen = false;
  bool isBuildSummaryOpen = false;
  bool isPauseMenuOpen = false;
  bool isRunStarted = false;
  bool isResultShowing = false;
  double runElapsedSeconds = 0;
  double _attackCooldownLeft = 0;
  bool _memoryRoomPending = false;
  Rect? _cameraWorldBounds;

  @override
  Color backgroundColor() => const Color(0xFF08090D);

  @override
  void update(double dt) {
    if (juice.isHitStopping) {
      juice.updateHitStop(dt);
      juice.updateCamera(dt);
      return;
    }

    super.update(dt);
    if (isRunStarted && !isResultShowing && !gameState.isGameOver) {
      runElapsedSeconds += dt;
    }
    if (_attackCooldownLeft > 0) {
      _attackCooldownLeft -= dt;
    }
    if (gameState.isGameOver && !isResultShowing && !_tryRevive()) {
      endRun(clear: false);
    }
    _notifyUpdate(dt);
    juice.updateCamera(dt);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await LocalizationService.instance.load();
    await metaProgress.load();
    await bgm.initialize();
    _configureUnlockedPools();

    camera = CameraComponent.withFixedResolution(
      world: world,
      width: cameraWidth,
      height: cameraHeight,
    );
    camera.viewfinder.anchor = Anchor.center;
    addAll([world, camera]);

    player = Player(position: Vector2.zero());
    juice = JuiceManager(this);
    world.addAll([WorldGrid(), player]);
    camera.viewfinder.position = player.position.clone();
    roomManager = RoomManager();
    add(roomManager);
    overlays.add('title');
    unawaited(bgm.playTrack(BgmTrack.title));
    pauseEngine();
  }

  void updateCameraBounds(Rect bounds) {
    _cameraWorldBounds = bounds;
    camera.setBounds(
      flame_geometry.Rectangle.fromRect(bounds),
      considerViewport: true,
    );
    camera.viewfinder.position = clampCameraPosition(camera.viewfinder.position);
  }

  Vector2 clampCameraPosition(Vector2 target) {
    final bounds = _cameraWorldBounds;
    if (bounds == null) {
      return target;
    }

    final zoom = camera.viewfinder.zoom;
    final halfWidth = cameraWidth / zoom / 2;
    final halfHeight = cameraHeight / zoom / 2;
    final center = bounds.center;
    final clamped = target.clone();

    if (bounds.width <= halfWidth * 2) {
      clamped.x = center.dx;
    } else {
      clamped.x = clamped.x.clamp(
        bounds.left + halfWidth,
        bounds.right - halfWidth,
      );
    }

    if (bounds.height <= halfHeight * 2) {
      clamped.y = center.dy;
    } else {
      clamped.y = clamped.y.clamp(
        bounds.top + halfHeight,
        bounds.bottom - halfHeight,
      );
    }

    return clamped;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      final fragment = nearbyInscriptionFragment;
      if (fragment != null) {
        openSinInscription(fragment);
        return KeyEventResult.handled;
      }
    }
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyB ||
            event.logicalKey == LogicalKeyboardKey.tab)) {
      toggleBuildSummary();
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      togglePauseMenu();
      return KeyEventResult.handled;
    }

    super.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!isRunStarted ||
        gameState.isGameOver ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen) {
      return;
    }

    final target = camera.globalToLocal(event.canvasPosition);
    shootAt(target);
  }

  void shootAt(Vector2 target) {
    if (!isRunStarted) {
      return;
    }

    if (_attackCooldownLeft > 0) {
      return;
    }

    final direction = target - player.position;
    if (direction.isZero()) {
      return;
    }
    player.faceTarget(target);

    final stats = gameState.stats;
    _notifyAttack();
    final damageMultiplier = _attackDamageMultiplier();
    final attackSpeedMultiplier = _attackSpeedMultiplier();
    final isCritical = _random.nextDouble() < stats.criticalChance;
    final damage =
        stats.attackDamage *
        damageMultiplier *
        (isCritical ? stats.criticalMultiplier : 1);
    final baseDirection = direction.normalized();
    final projectileCount = stats.projectileCount.clamp(1, 7);
    final spread = stats.projectileSpread;
    final startAngle = projectileCount == 1 ? 0.0 : -spread / 2;
    final step = projectileCount == 1 ? 0.0 : spread / (projectileCount - 1);
    for (var i = 0; i < projectileCount; i += 1) {
      final shotDirection = baseDirection.clone()
        ..rotate(startAngle + step * i);
      world.add(
        Projectile(
          position: player.position.clone(),
          direction: shotDirection,
          damage: damage.round(),
          speed: stats.projectileSpeed,
          radius: stats.projectileRadius,
          leavesFire: gameState.buildReport.hasFireChain,
          pierce: stats.projectilePierce,
          chainCount: stats.chainCount,
          chainRange: stats.chainRange,
          executeThreshold: stats.executeThreshold.clamp(0, 0.35),
        ),
      );
    }
    audio.playAttack();
    _attackCooldownLeft = 1 / (stats.attackSpeed * attackSpeedMultiplier);
  }

  void openContract() {
    if (!isRunStarted ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen ||
        isMerchantOpen ||
        isRouteChoiceOpen ||
        isChoosingRelic ||
        gameState.isGameOver) {
      return;
    }

    currentPacts = contractSystem.generatePacts();
    isChoosingPact = true;
    overlays.add('contract');
    pauseEngine();
  }

  void openRelicChoice() {
    if (isRunStarted || isChoosingRelic || !metaProgress.isLoaded) {
      return;
    }

    final choiceCount = metaProgress.relicChoiceCount;
    if (choiceCount <= 0 || metaProgress.unlockedRelicIds.isEmpty) {
      startRun();
      return;
    }

    currentRelicChoices =
        relicTable
            .where((relic) => metaProgress.unlockedRelicIds.contains(relic.id))
            .toList()
          ..shuffle(_random);
    currentRelicChoices = currentRelicChoices.take(choiceCount).toList();
    isChoosingRelic = true;
    overlays.add('relic');
  }

  void openUnlockScreen() {
    if (isRunStarted || isUnlockScreenOpen) {
      return;
    }

    overlays.remove('title');
    overlays.add('unlock');
    isUnlockScreenOpen = true;
  }

  void closeUnlockScreen() {
    if (!isUnlockScreenOpen) {
      return;
    }

    overlays.remove('unlock');
    overlays.add('title');
    isUnlockScreenOpen = false;
  }

  void chooseRelic(Relic relic) {
    if (!isChoosingRelic) {
      return;
    }

    gameState.selectRelic(relic, player);
    if (relic.id == 'contract_seal' || relic.id == 'calamity_seal') {
      grantRandomCurse();
    }
    resolveBuild();
    overlays.remove('relic');
    overlays.remove('unlock');
    isChoosingRelic = false;
    startRun();
  }

  void choosePact(Pact pact) {
    gameState.addPact(pact.blessing, pact.curse, player);
    roomManager.markCurrentPactClaimed();
    resolveBuild();
    audio.playContract();
    juice.contractAccepted(player.position);
    overlays.remove('contract');
    isChoosingPact = false;
    resumeEngine();
  }

  void openBossBoonChoice() {
    if (!isRunStarted ||
        isChoosingBossBoon ||
        isChoosingPact ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen ||
        isMerchantOpen ||
        isChoosingRelic ||
        gameState.isGameOver) {
      return;
    }

    currentBossBoonChoices = [...bossBoonTable]..shuffle(_random);
    currentBossBoonChoices = currentBossBoonChoices
        .take((3 + gameState.stats.bossBoonChoiceBonus).clamp(3, 5))
        .toList();
    isChoosingBossBoon = true;
    overlays.add('boss_boon');
    pauseEngine();
  }

  void chooseBossBoon(BossBoon boon) {
    if (!isChoosingBossBoon) {
      return;
    }

    gameState.addBossBoon(boon, player);
    resolveBuild();
    juice.blessingAcquired(player.position);
    overlays.remove('boss_boon');
    isChoosingBossBoon = false;
    if (_memoryRoomPending) {
      _memoryRoomPending = false;
      resumeEngine();
    } else {
      resumeEngine();
    }
  }

  void onBossDefeated() {
    _memoryRoomPending = false;
    openBossBoonChoice();
  }

  void openMemoryRoom() {
    if (!isRunStarted ||
        isMemoryRoomOpen ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMerchantOpen ||
        isChoosingRelic ||
        gameState.isGameOver) {
      return;
    }

    _memoryRoomPending = false;
    final node = roomManager.currentNode;
    if (node?.type == RoomType.memory && node?.memoryRewardClaimed == true) {
      currentMemoryFragment = null;
    } else {
      currentMemoryFragment = metaProgress.nextMemoryFragment;
    }
    if (currentMemoryFragment != null) {
      if (node?.type == RoomType.memory) {
        node?.memoryRewardClaimed = true;
      }
      metaProgress.revealStoryFragment(currentMemoryFragment!.id);
    }
    isMemoryRoomOpen = true;
    unawaited(bgm.playTrack(BgmTrack.memory));
    overlays.add('memory_room');
    pauseEngine();
  }

  void closeMemoryRoom() {
    if (!isMemoryRoomOpen) {
      return;
    }

    overlays.remove('memory_room');
    currentMemoryFragment = null;
    isMemoryRoomOpen = false;
    resumeEngine();
  }

  void openSinInscription(StoryFragment fragment) {
    if (!isRunStarted ||
        isInscriptionOpen ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isMerchantOpen ||
        isChoosingRelic ||
        gameState.isGameOver) {
      return;
    }

    currentInscriptionFragment = fragment;
    metaProgress.revealStoryFragment(fragment.id);
    isInscriptionOpen = true;
    overlays.add('inscription');
    pauseEngine();
  }

  void closeSinInscription() {
    if (!isInscriptionOpen) {
      return;
    }

    overlays.remove('inscription');
    currentInscriptionFragment = null;
    isInscriptionOpen = false;
    resumeEngine();
  }

  void setNearbyInscription(StoryFragment? fragment) {
    nearbyInscriptionFragment = fragment;
  }

  void openCodex() {
    if (isCodexOpen || isChoosingRelic || isResultShowing) {
      return;
    }

    if (isRunStarted && !isPauseMenuOpen) {
      isPauseMenuOpen = true;
      overlays.add('pause');
      pauseEngine();
    }
    isCodexOpen = true;
    overlays.add('codex');
  }

  void closeCodex() {
    if (!isCodexOpen) {
      return;
    }

    overlays.remove('codex');
    isCodexOpen = false;
  }

  void openMerchant() {
    if (!isRunStarted ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen ||
        isMerchantOpen ||
        isRouteChoiceOpen ||
        isChoosingRelic ||
        gameState.isGameOver) {
      return;
    }

    _currentOfferingSystem();
    isMerchantOpen = true;
    overlays.add('merchant');
    pauseEngine();
  }

  void closeMerchant() {
    if (!isMerchantOpen) {
      return;
    }

    overlays.remove('merchant');
    isMerchantOpen = false;
    resumeEngine();
  }

  void openRouteChoice() {
    if (!isRunStarted ||
        isRouteChoiceOpen ||
        isChoosingRelic ||
        isResultShowing) {
      return;
    }

    isRouteChoiceOpen = true;
    overlays.add('route');
    pauseEngine();
  }

  void closeRouteChoice() {
    if (!isRouteChoiceOpen) {
      return;
    }

    overlays.remove('route');
    isRouteChoiceOpen = false;
    resumeEngine();
  }

  void toggleBuildSummary() {
    if (!isRunStarted ||
        isResultShowing ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen ||
        isMerchantOpen ||
        isRouteChoiceOpen ||
        isChoosingRelic ||
        isPauseMenuOpen) {
      return;
    }

    if (isBuildSummaryOpen) {
      closeBuildSummary();
    } else {
      isBuildSummaryOpen = true;
      overlays.add('build');
      pauseEngine();
    }
  }

  void closeBuildSummary() {
    if (!isBuildSummaryOpen) {
      return;
    }

    overlays.remove('build');
    isBuildSummaryOpen = false;
    resumeEngine();
  }

  void togglePauseMenu() {
    if (isCodexOpen) {
      closeCodex();
      return;
    }

    if (!isRunStarted ||
        isResultShowing ||
        isChoosingPact ||
        isChoosingBossBoon ||
        isMemoryRoomOpen ||
        isInscriptionOpen ||
        isCodexOpen ||
        isMerchantOpen ||
        isRouteChoiceOpen ||
        isChoosingRelic) {
      return;
    }

    if (isBuildSummaryOpen) {
      closeBuildSummary();
      return;
    }

    if (isPauseMenuOpen) {
      closePauseMenu();
    } else {
      isPauseMenuOpen = true;
      overlays.add('pause');
      pauseEngine();
    }
  }

  void closePauseMenu() {
    if (!isPauseMenuOpen) {
      return;
    }

    if (isCodexOpen) {
      closeCodex();
    }
    overlays.remove('pause');
    isPauseMenuOpen = false;
    resumeEngine();
  }

  void abandonRun() {
    if (isResultShowing) {
      return;
    }

    overlays.remove('pause');
    overlays.remove('build');
    isPauseMenuOpen = false;
    isBuildSummaryOpen = false;
    endRun(clear: false);
  }

  void chooseRoute(RoomType type) {
    roomManager.chooseNextRoom(type);
  }

  void buyRemoveCurse(Curse curse) {
    if (!gameState.spendEssence(Balance.removeCurseCost)) {
      return;
    }

    gameState.removeCurse(curse, player);
    resolveBuild();
  }

  void buyDeeperPact() {
    final offering = _currentOfferingSystem();
    if (offering.deeperPactSold) {
      return;
    }

    gameState.addBlessing(offering.deepBlessing, player);
    gameState.addCurse(offering.deepCurse, player);
    resolveBuild();
    juice.contractAccepted(player.position);
    offering.markDeeperPactSold();
    gameState.refresh();
  }

  void buyMerchantBlessing() {
    final offering = _currentOfferingSystem();
    if (offering.blessingOfferSold) {
      return;
    }

    final offer = offering.blessingOffer;
    if (!gameState.spendEssence(offer.price)) {
      return;
    }

    gameState.addBlessing(offer.blessing, player);
    resolveBuild();
    juice.blessingAcquired(player.position);
    offering.markBlessingSold();
    gameState.refresh();
  }

  void rerollMerchant() {
    if (!gameState.spendEssence(Balance.merchantRerollCost)) {
      return;
    }

    _currentOfferingSystem().roll();
    gameState.refresh();
  }

  MerchantSystem get currentOfferingSystem => _currentOfferingSystem();

  void addTrauma({required double strength, required double duration}) {
    juice.impact(strength: strength, duration: duration);
  }

  void hitStop(double duration) {
    // Kept for compatibility with older call sites. New feedback goes through
    // JuiceManager event methods so intensity stays capped in one place.
  }

  RunContext get modifierContext {
    return RunContext(
      player: player,
      gameState: gameState,
      modifiers: gameState.modifiers,
    );
  }

  void notifyPlayerHit(double damage) {
    final ctx = modifierContext;
    for (final modifier in gameState.modifiers) {
      modifier.onHit(ctx, damage);
    }
  }

  void notifyEnemyKilled(Enemy enemy) {
    gameState.addKill();
    final ctx = modifierContext;
    for (final modifier in gameState.modifiers) {
      modifier.onKill(ctx, enemy);
    }
    if (gameState.buildReport.hasReapersDeal) {
      player.grantInvincibility(0.45);
      player.grantSpeedBuff(multiplier: 1.35, duration: 1.2);
    }
  }

  void notifyRoomClear() {
    resolveBuild();
    final ctx = modifierContext;
    for (final modifier in gameState.modifiers) {
      modifier.onRoomClear(ctx);
    }
  }

  void _notifyAttack() {
    final ctx = modifierContext;
    for (final modifier in gameState.modifiers) {
      modifier.onAttack(ctx);
    }
  }

  void _notifyUpdate(double dt) {
    final ctx = modifierContext;
    for (final modifier in gameState.modifiers) {
      modifier.onUpdate(ctx, dt);
    }
  }

  void resolveBuild() {
    final previousReport = gameState.buildReport;
    final nextReport = synergyResolver.evaluate(gameState.modifiers);
    gameState.updateBuildReport(nextReport);
    audio.setCurseIntensity(gameState.curses.length);

    final previousSynergyIds = previousReport.synergies
        .map((s) => s.id)
        .toSet();
    final nextSynergyIds = nextReport.synergies.map((s) => s.id).toSet();
    final previousConflictIds = previousReport.conflicts
        .map((c) => c.id)
        .toSet();
    final nextConflictIds = nextReport.conflicts.map((c) => c.id).toSet();
    final synergyActivated = nextSynergyIds
        .difference(previousSynergyIds)
        .isNotEmpty;
    final conflictActivated = nextConflictIds
        .difference(previousConflictIds)
        .isNotEmpty;
    juice.buildShift(
      position: player.position,
      synergyActivated: synergyActivated,
      conflictActivated: conflictActivated,
    );
  }

  void grantRandomBlessing() {
    final blessings =
        blessingTable
            .where(
              (blessing) =>
                  metaProgress.unlockedBlessingIds.contains(blessing.id),
            )
            .toList()
          ..shuffle(_random);
    final blessing = blessings.first;
    gameState.addBlessing(blessing, player);
    resolveBuild();
    juice.blessingAcquired(player.position);
    debugPrint('Treasure blessing granted: ${blessing.name}');
  }

  void grantRandomCurse() {
    final curses =
        curseTable
            .where((curse) => metaProgress.unlockedCurseIds.contains(curse.id))
            .toList()
          ..shuffle(_random);
    final curse = curses.first;
    gameState.addCurse(curse, player);
    resolveBuild();
    juice.curseAcquired(player.position);
    debugPrint('Challenge curse accepted: ${curse.name}');
  }

  double _attackDamageMultiplier() {
    var multiplier = 1.0;
    if (gameState.buildReport.hasGlassCannon) {
      final missingHpRatio = 1 - gameState.hpRatio;
      multiplier += missingHpRatio * 0.75;
    }
    if (gameState.stats.lowHpPowerMultiplier > 0) {
      final missingHpRatio = 1 - gameState.hpRatio;
      multiplier += missingHpRatio * gameState.stats.lowHpPowerMultiplier;
    }
    if (gameState.buildReport.hasRushSlayer && player.isMoving) {
      multiplier += 0.2;
    }
    return multiplier;
  }

  double _attackSpeedMultiplier() {
    var multiplier = 1.0;
    if (gameState.buildReport.hasRushSlayer && player.isMoving) {
      multiplier += 0.25;
    }
    if (player.isMoving) {
      multiplier *= gameState.stats.movingAttackSpeedMultiplier;
    }
    if (gameState.stats.lowHpPowerMultiplier > 0) {
      final missingHpRatio = 1 - gameState.hpRatio;
      multiplier +=
          missingHpRatio * gameState.stats.lowHpPowerMultiplier * 0.35;
    }
    return multiplier;
  }

  void startRun() {
    if (isRunStarted) {
      return;
    }

    bgm.resetBossRotation();
    gameState.applyMetaBonuses(metaProgress);
    _grantStartingBossBoon();
    gameState.rebuildStats(player);
    gameState.refresh();
    isRunStarted = true;
    overlays.remove('title');
    overlays.remove('relic');
    overlays.remove('unlock');
    overlays.add('hud');
    playBgmForCurrentRoom();
    resumeEngine();
  }

  void endRun({required bool clear}) {
    if (isResultShowing) {
      return;
    }

    isResultShowing = true;
    final reward = metaProgress.recordRun(
      floor: gameState.maxFloorReached,
      room: gameState.room,
      kills: gameState.kills,
      curseCount: gameState.curses.length,
      score: gameState.score,
      cleared: clear,
    );
    gameState.setMetaReward(reward);
    audio.playRunEnd();
    unawaited(bgm.playTrack(BgmTrack.death));
    overlays.remove('contract');
    overlays.remove('boss_boon');
    overlays.remove('memory_room');
    overlays.remove('inscription');
    overlays.remove('codex');
    overlays.remove('merchant');
    overlays.remove('route');
    overlays.remove('relic');
    overlays.remove('build');
    overlays.remove('pause');
    isChoosingBossBoon = false;
    isMemoryRoomOpen = false;
    isInscriptionOpen = false;
    isCodexOpen = false;
    _memoryRoomPending = false;
    currentMemoryFragment = null;
    currentInscriptionFragment = null;
    nearbyInscriptionFragment = null;
    overlays.add('result');
    pauseEngine();
  }

  void playBgmForCurrentRoom() {
    if (!isRunStarted || isResultShowing) {
      return;
    }

    final node = roomManager.currentNode;
    if (node == null) {
      unawaited(bgm.playTrack(BgmTrack.combat));
      return;
    }

    if (node.type == RoomType.boss && !node.cleared) {
      unawaited(bgm.playBossBgm());
      return;
    }

    if (node.type == RoomType.memory) {
      unawaited(bgm.playTrack(BgmTrack.memory));
      return;
    }

    unawaited(bgm.playTrack(BgmTrack.combat));
  }

  @override
  void onRemove() {
    bgm.dispose();
    super.onRemove();
  }

  bool _tryRevive() {
    if (!gameState.reviveAtHalfHp()) {
      return false;
    }

    grantRandomCurse();
    player.grantInvincibility(1.25);
    player.position = Vector2.zero();
    juice.curseAcquired(player.position);
    debugPrint('Revival consumed: half HP and a random curse gained.');
    return true;
  }

  void _grantStartingBossBoon() {
    if (!metaProgress.startingBossBoonUnlocked ||
        gameState.bossBoons.isNotEmpty) {
      return;
    }

    final boons = [...bossBoonTable]..shuffle(_random);
    final boon = boons.first;
    gameState.addBossBoon(boon, player);
    resolveBuild();
    debugPrint('Starting Boss Boon granted: ${boon.name}');
  }

  Future<void> unlockMeta(String id) async {
    final unlocked = await metaProgress.unlock(id);
    if (!unlocked) {
      return;
    }

    _configureUnlockedPools();
    for (final offering in _offeringSystems.values) {
      _configureOfferingSystem(offering);
    }
    gameState.refresh();
  }

  void _configureUnlockedPools() {
    contractSystem.unlockedBlessingIds = metaProgress.unlockedBlessingIds;
    contractSystem.unlockedCurseIds = metaProgress.unlockedCurseIds;
    for (final offering in _offeringSystems.values) {
      _configureOfferingSystem(offering);
    }
  }

  MerchantSystem _currentOfferingSystem() {
    final key = _currentOfferingKey();
    return _offeringSystems.putIfAbsent(key, () {
      final offering = MerchantSystem();
      _configureOfferingSystem(offering);
      offering.roll();
      return offering;
    });
  }

  String _currentOfferingKey() {
    final node = roomManager.currentNode;
    if (node == null) {
      return 'floor:${roomManager.currentLevel}:unknown';
    }
    return 'floor:${roomManager.currentLevel}:${node.key}';
  }

  void _configureOfferingSystem(MerchantSystem offering) {
    offering.unlockedBlessingIds = metaProgress.unlockedBlessingIds;
    offering.unlockedCurseIds = metaProgress.unlockedCurseIds;
  }
}
