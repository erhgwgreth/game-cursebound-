import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';
import '../data/balance.dart';
import '../data/dungeon_map.dart';
import '../data/enemy_data.dart';
import '../data/room_type.dart';
import '../data/story_fragment.dart';
import '../systems/room_manager.dart';
import 'altar.dart';
import 'boss.dart';
import 'enemy.dart';
import 'miniboss.dart';
import 'memory_echo.dart';
import 'offering_altar.dart';
import 'player.dart';
import 'stairs.dart';
import 'story_inscription.dart';

class Room extends PositionComponent with HasGameReference<CurseboundGame> {
  Room({required this.index, required this.node, required this.manager})
    : super(anchor: Anchor.center, priority: -50);

  static final Vector2 roomSize = Vector2(900, 560);
  static const double wallThickness = 24;

  final int index;
  final RoomNode node;
  final RoomManager manager;

  int _aliveEnemies = 0;
  bool _isCleared = false;

  RoomType get type => node.type;

  Vector2 get scaledRoomSize {
    final size = Balance.roomSize(game.gameState.floor);
    return Vector2(size.width, size.height);
  }

  bool get isBossRoom => type == RoomType.boss;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _isCleared = node.cleared;
    _buildWalls();
    if (_isCleared) {
      openDoors();
      _spawnPersistentRoomObjects();
      _spawnStoryInscription();
      _spawnPendingReward();
      return;
    }

    switch (type) {
      case RoomType.start:
        _clearRoom(spawnAltar: false);
      case RoomType.normal:
        _spawnEnemies();
      case RoomType.treasure:
        _spawnMiniBoss();
      case RoomType.miniboss:
        _spawnMiniBoss();
      case RoomType.elite:
        _spawnEliteEnemies();
      case RoomType.challenge:
        _enterChallengeRoom();
      case RoomType.merchant:
        _enterOfferingRoom();
      case RoomType.offering:
        _enterOfferingRoom();
      case RoomType.upstairs:
        _enterStairsRoom();
      case RoomType.memory:
        _enterMemoryRoom();
      case RoomType.boss:
        _spawnBoss();
    }
  }

  bool get isCleared => _isCleared;

  Rect get bounds => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: scaledRoomSize.x,
    height: scaledRoomSize.y,
  );

  void clampPlayer(Player player) {
    final halfPlayer = player.size.x / 2;
    final playable = bounds.deflate(wallThickness + halfPlayer);

    player.position.x = player.position.x.clamp(playable.left, playable.right);

    player.position.y = player.position.y.clamp(playable.top, playable.bottom);
  }

  void onEnemyKilled() {
    _aliveEnemies -= 1;
    _tryClearCombatRoom();
  }

  void onEnemySpawned() {
    _aliveEnemies += 1;
  }

  void _tryClearCombatRoom() {
    if (_isCleared) {
      return;
    }

    final livingEnemies = children.whereType<Enemy>().where(
      (enemy) => enemy.isMounted && enemy.hp > 0,
    );
    final livingBosses = children.whereType<Boss>().where(
      (boss) => boss.isMounted && boss.hp > 0,
    );
    final livingMiniBosses = children.whereType<MiniBoss>().where(
      (boss) => boss.isMounted && boss.hp > 0,
    );
    if (_aliveEnemies <= 0 || (livingEnemies.isEmpty && livingBosses.isEmpty)) {
      if (livingMiniBosses.isNotEmpty) {
        return;
      }
      _clearRoom();
    }
  }

  void _buildWalls() {
    final size = scaledRoomSize;
    final w = size.x;
    final h = size.y;
    const t = wallThickness;

    addAll([
      _Wall(position: Vector2(0, -h / 2 + t / 2), size: Vector2(w, t)),
      _Wall(position: Vector2(0, h / 2 - t / 2), size: Vector2(w, t)),
      _Wall(position: Vector2(-w / 2 + t / 2, 0), size: Vector2(t, h)),
      _Wall(position: Vector2(w / 2 - t / 2, 0), size: Vector2(t, h)),
    ]);

    for (final direction in node.exits) {
      add(
        ExitDoor.forDirection(
          direction: direction,
          isOpen: _isCleared,
          roomSize: size,
        ),
      );
    }
  }

  void _spawnEnemies() {
    final count = Balance.normalEnemyCount(
      floor: game.gameState.floor,
      room: index,
    );
    final healthScale = Balance.enemyHealthScale(
      floor: game.gameState.floor,
      room: index,
    );
    final damageScale = Balance.enemyDamageScale(
      floor: game.gameState.floor,
      room: index,
    );
    final spawns = _combatSpawnPoints();
    final random = _roomRandom();
    final kinds = _unlockedEnemyKinds();

    _aliveEnemies = count;
    addAll(
      spawns.take(count).map((position) {
        final kind = kinds[random.nextInt(kinds.length)];
        return Enemy(
          position: position,
          kind: kind,
          onDeath: onEnemyKilled,
          onSpawnedEnemy: onEnemySpawned,
          healthMultiplier: healthScale,
          damage: (Enemy.contactDamage * damageScale).round(),
        );
      }),
    );
  }

  void _spawnEliteEnemies() {
    final count = Balance.eliteEnemyCount(game.gameState.floor);
    final healthScale =
        Balance.enemyHealthScale(floor: game.gameState.floor, room: index) *
        1.05;
    final damageScale = Balance.enemyDamageScale(
      floor: game.gameState.floor,
      room: index,
    );
    final random = _roomRandom();
    final kinds = _unlockedEnemyKinds();
    final modifiers = _unlockedEliteModifiers();
    final spawns = _combatSpawnPoints();

    _aliveEnemies = count;
    addAll(
      spawns.take(count).map((position) {
        final modifier = modifiers.isEmpty
            ? EliteModifier.gale
            : modifiers[random.nextInt(modifiers.length)];
        return Enemy(
          position: position,
          kind: kinds[random.nextInt(kinds.length)],
          eliteModifier: modifier,
          onDeath: onEnemyKilled,
          onSpawnedEnemy: onEnemySpawned,
          healthMultiplier:
              Balance.eliteHealthBonus(game.gameState.floor) * healthScale,
          damage: (15 * damageScale).round(),
          speed: 118 + game.gameState.floor.clamp(0, 12) * 2,
          radius: 24,
          color: const Color(0xFF9B8190),
        );
      }),
    );
  }

  void _enterChallengeRoom() {
    game.grantRandomCurse();
    _spawnEnemies();
    game.gameState.addEssence(10 + game.gameState.curses.length * 2);
  }

  void _spawnMiniBoss() {
    _aliveEnemies = 1;
    add(
      MiniBoss(
        position: Vector2(scaledRoomSize.x * 0.17, 0),
        onDeath: onEnemyKilled,
      ),
    );
  }

  void _enterOfferingRoom() {
    add(OfferingAltar(position: Vector2.zero()));
    _clearRoom(spawnAltar: false);
  }

  void _enterStairsRoom() {
    add(Stairs.up(position: Vector2.zero()));
    _clearRoom(spawnAltar: false);
  }

  void _enterMemoryRoom() {
    add(MemoryEcho(position: Vector2.zero()));
    _clearRoom(spawnAltar: false);
  }

  void _spawnBoss() {
    _aliveEnemies = 1;
    add(
      Boss(
        position: Vector2(scaledRoomSize.x * 0.24, 0),
        onDeath: onEnemyKilled,
      ),
    );
  }

  List<Vector2> _combatSpawnPoints() {
    final halfW = scaledRoomSize.x / 2 - wallThickness - 72;
    final halfH = scaledRoomSize.y / 2 - wallThickness - 72;
    final xs = [-0.72, 0.68, -0.58, 0.62, 0.0, 0.0, -0.24, 0.32, -0.42];
    final ys = [-0.56, -0.48, 0.54, 0.5, -0.72, 0.72, 0.0, -0.08, 0.16];
    return [
      for (var i = 0; i < xs.length; i += 1)
        Vector2(halfW * xs[i], halfH * ys[i]),
    ];
  }

  void _clearRoom({bool spawnAltar = true}) {
    _isCleared = true;
    if (type == RoomType.treasure || type == RoomType.miniboss) {
      game.grantRandomBlessing();
      spawnAltar = false;
    }
    if (type == RoomType.boss) {
      spawnAltar = false;
    }
    if (spawnAltar) {
      node.pactRewardPending = true;
      add(Altar(position: Vector2.zero()));
    }
    _spawnStoryInscription();
    openDoors();
    manager.onRoomCleared();
  }

  void _spawnPendingReward() {
    if (node.pactRewardPending &&
        !children.whereType<Altar>().any((altar) => altar.isMounted)) {
      add(Altar(position: Vector2.zero()));
    }
  }

  void _spawnPersistentRoomObjects() {
    if (type == RoomType.start && manager.currentLevel > 1) {
      if (!children.whereType<Stairs>().any((stairs) => !stairs.isUp)) {
        add(Stairs.down(position: Vector2.zero()));
      }
    }
    if (type == RoomType.upstairs &&
        !children.whereType<Stairs>().any((stairs) => stairs.isUp)) {
      add(Stairs.up(position: Vector2.zero()));
    }
    if ((type == RoomType.offering || type == RoomType.merchant) &&
        !children.whereType<OfferingAltar>().any((altar) => altar.isMounted)) {
      add(OfferingAltar(position: Vector2.zero()));
    }
    if (type == RoomType.memory &&
        !children.whereType<MemoryEcho>().any((echo) => echo.isMounted)) {
      add(MemoryEcho(position: Vector2.zero()));
    }
  }

  void _spawnStoryInscription() {
    if (type != RoomType.memory) {
      return;
    }
    if (children.whereType<StoryInscription>().any((item) => item.isMounted)) {
      return;
    }

    final fragments = sinFragmentsForTheme(
      sinThemeForFloor(manager.currentLevel),
    );
    if (fragments.isEmpty) {
      return;
    }
    final random = _roomRandom();
    final fragment = fragments[random.nextInt(fragments.length)];
    final x = -scaledRoomSize.x / 2 + wallThickness + 86;
    final y = -scaledRoomSize.y / 2 + wallThickness + 72;
    add(StoryInscription(position: Vector2(x, y), fragment: fragment));
  }

  void openDoors() {
    for (final door in children.whereType<ExitDoor>()) {
      door.open();
    }
  }

  void addExitDoor(Direction direction) {
    if (children.whereType<ExitDoor>().any(
      (door) => door.direction == direction,
    )) {
      return;
    }
    final door = ExitDoor.forDirection(
      direction: direction,
      isOpen: _isCleared,
      roomSize: scaledRoomSize,
    );
    add(door);
  }

  Random _roomRandom() {
    final seed =
        manager.seed ^
        (game.gameState.floor * 73856093) ^
        (node.x * 19349663) ^
        (node.y * 83492791);
    return Random(seed);
  }

  List<EnemyKind> _unlockedEnemyKinds() {
    const orderedKinds = [
      EnemyKind.charger,
      EnemyKind.caster,
      EnemyKind.bomber,
      EnemyKind.warden,
      EnemyKind.hexer,
      EnemyKind.artillery,
      EnemyKind.mirrorWraith,
      EnemyKind.summoner,
      EnemyKind.splitter,
      EnemyKind.acolyte,
    ];
    return orderedKinds
        .take(Balance.unlockedEnemyKindCount(game.gameState.floor))
        .toList();
  }

  List<EliteModifier> _unlockedEliteModifiers() {
    const orderedModifiers = [
      EliteModifier.gale,
      EliteModifier.runicShield,
      EliteModifier.thorns,
    ];
    return orderedModifiers
        .take(Balance.unlockedEliteModifierCount(game.gameState.floor))
        .toList();
  }
}

class _Wall extends RectangleComponent {
  _Wall({required super.position, required super.size})
    : super(
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF181B25),
      );
}

class ExitDoor extends RectangleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  ExitDoor._({
    required super.position,
    required super.size,
    required this.direction,
    required bool isOpen,
  }) : _isOpen = isOpen,
       super(
         anchor: Anchor.center,
         paint: Paint()
           ..color = isOpen ? const Color(0xFFD7B84F) : const Color(0xFF3C1420),
       );

  factory ExitDoor.forDirection({
    required Direction direction,
    required bool isOpen,
    required Vector2 roomSize,
  }) {
    final halfW = roomSize.x / 2 - Room.wallThickness / 2;
    final halfH = roomSize.y / 2 - Room.wallThickness / 2;
    return switch (direction) {
      Direction.up => ExitDoor._(
        position: Vector2(0, -halfH),
        size: Vector2(120, 34),
        direction: direction,
        isOpen: isOpen,
      ),
      Direction.down => ExitDoor._(
        position: Vector2(0, halfH),
        size: Vector2(120, 34),
        direction: direction,
        isOpen: isOpen,
      ),
      Direction.left => ExitDoor._(
        position: Vector2(-halfW, 0),
        size: Vector2(34, 120),
        direction: direction,
        isOpen: isOpen,
      ),
      Direction.right => ExitDoor._(
        position: Vector2(halfW, 0),
        size: Vector2(34, 120),
        direction: direction,
        isOpen: isOpen,
      ),
    };
  }

  final Direction direction;
  bool _isOpen;
  bool _isTransitioning = false;

  static const double activationDepth = 104;
  static const double activationWidth = 148;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  void open() {
    _isOpen = true;
    paint.color = const Color(0xFFD7B84F);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isOpen && !_isTransitioning && _isPlayerInActivationZone()) {
      _isTransitioning = true;
      game.roomManager.tryMove(direction);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (_isOpen && !_isTransitioning && other == game.player) {
      _isTransitioning = true;
      game.roomManager.tryMove(direction);
    }
  }

  bool _isPlayerInActivationZone() {
    final playerPosition = game.player.position;
    final dx = (playerPosition.x - position.x).abs();
    final dy = (playerPosition.y - position.y).abs();

    return switch (direction) {
      Direction.up ||
      Direction.down => dx <= activationWidth / 2 && dy <= activationDepth,
      Direction.left ||
      Direction.right => dx <= activationDepth && dy <= activationWidth / 2,
    };
  }
}
