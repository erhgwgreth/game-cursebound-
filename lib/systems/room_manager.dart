import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../components/boss.dart';
import '../components/enemy.dart';
import '../components/miniboss.dart';
import '../components/projectile.dart';
import '../components/room.dart';
import '../data/balance.dart';
import '../data/dungeon_map.dart';
import '../data/room_type.dart';
import '../game/cursebound_game.dart';

enum FloorEntry { start, upstairsRoom }

class RoomManager extends Component with HasGameReference<CurseboundGame> {
  RoomManager({int? seed}) : _seed = seed ?? Random().nextInt(1 << 31);

  final int _seed;
  final Random _random = Random();
  final Map<int, DungeonFloor> floors = {};

  late DungeonMap dungeon;
  Room? _currentRoom;
  RoomNode? _currentNode;
  int _roomVisitCount = 0;
  int currentLevel = 1;
  List<RoomType> nextRoomChoices = [];
  bool isChoosingRoute = false;

  Room? get currentRoom => _currentRoom;

  RoomNode? get currentNode => _currentNode;

  int get currentRoomIndex => _roomVisitCount;

  int get seed => _seed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final floor = _floorFor(1);
    currentLevel = 1;
    dungeon = floor.map;
    _loadNode(floor.map.start, entryDirection: null);
    debugPrint(
      'Dungeon base seed: $_seed, floor 1 rooms: ${dungeon.nodes.length}',
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _currentRoom?.clampPlayer(game.player);
  }

  void tryMove(Direction direction) {
    final current = _currentNode;
    if (current == null || _currentRoom == null || !_currentRoom!.isCleared) {
      return;
    }

    final next = dungeon.neighbor(current, direction);
    if (next == null) {
      return;
    }

    _loadNode(next, entryDirection: direction.opposite);
  }

  void goUpstairs() {
    _changeFloor(currentLevel + 1, entry: FloorEntry.start);
  }

  void goDownstairs() {
    if (currentLevel <= 1) {
      return;
    }

    _changeFloor(currentLevel - 1, entry: FloorEntry.upstairsRoom);
  }

  void chooseNextRoom(RoomType type) {
    debugLoadNextRoom(type);
  }

  void debugLoadNextRoom(RoomType type) {
    final node = RoomNode(x: 99 + _roomVisitCount, y: 0, type: type)
      ..cleared = false
      ..visited = false
      ..exits.add(Direction.left);
    dungeon.nodes[node.key] = node;
    _loadNode(node, entryDirection: Direction.left);
  }

  void debugWarpUp() {
    goUpstairs();
  }

  void onRoomCleared() {
    final node = _currentNode;
    if (node == null || node.cleared) {
      return;
    }

    node.cleared = true;
    game.gameState.setRoomCleared(true);
    final roomReward = Balance.roomEssenceReward(
      node.type,
      curseCount: game.gameState.curses.length,
    );
    final boostedRoomReward =
        node.type != RoomType.boss && game.gameState.bossFavorActive
        ? (roomReward * game.gameState.bossFavorEssenceMultiplier).round()
        : roomReward;
    game.gameState.addEssence(boostedRoomReward);
    game.notifyRoomClear();
    _currentRoom?.openDoors();

    if (node.type == RoomType.boss) {
      _tryOpenMemoryRoomFromBoss(node);
      game.gameState.addEssence(18 + currentLevel * 4);
      game.gameState.activateBossFavor();
      game.onBossDefeated();
    }
  }

  void _tryOpenMemoryRoomFromBoss(RoomNode bossNode) {
    if (bossNode.exits.any((direction) {
      final neighbor = dungeon.neighbor(bossNode, direction);
      return neighbor?.type == RoomType.memory;
    })) {
      return;
    }
    if (_random.nextDouble() >= Balance.bossMemoryRoomChance) {
      debugPrint('Memory room did not open on floor $currentLevel.');
      return;
    }

    for (final direction in Direction.values) {
      final x = bossNode.x + direction.dx;
      final y = bossNode.y + direction.dy;
      final key = RoomNode.keyFor(x, y);
      if (dungeon.nodes.containsKey(key)) {
        continue;
      }

      final memoryNode = RoomNode(x: x, y: y, type: RoomType.memory)
        ..cleared = true
        ..distanceFromStart = bossNode.distanceFromStart + 1
        ..exits.add(direction.opposite);
      dungeon.nodes[key] = memoryNode;
      bossNode.exits.add(direction);
      _currentRoom?.addExitDoor(direction);
      _currentRoom?.openDoors();
      debugPrint('Memory room opened at floor $currentLevel: $key');
      return;
    }
  }

  void markCurrentPactClaimed() {
    final node = _currentNode;
    if (node == null) {
      return;
    }

    node.pactRewardPending = false;
  }

  void _changeFloor(int level, {required FloorEntry entry}) {
    game.gameState.clearBossFavor();
    final floor = _floorFor(level);
    currentLevel = level;
    dungeon = floor.map;
    _pruneDistantFloors();

    final node = switch (entry) {
      FloorEntry.start => floor.map.start,
      FloorEntry.upstairsRoom => floor.map.upstairs,
    };
    game.gameState.setFloor(level);
    _loadNode(node, entryDirection: null);
    game.addTrauma(strength: 7, duration: 0.16);
    debugPrint('Entered floor $level, seed ${floor.seed}');
  }

  DungeonFloor _floorFor(int level) {
    final cached = floors[level];
    if (cached != null) {
      return cached;
    }

    final seed = _seed ^ (level * 73856093) ^ _random.nextInt(1 << 20);
    final map = DungeonMap.generate(
      seed: seed,
      floor: level,
      targetRooms: Balance.floorRoomCount(level),
    );
    final floor = DungeonFloor(level: level, seed: seed, map: map);
    floors[level] = floor;
    return floor;
  }

  void _pruneDistantFloors() {
    final min = currentLevel - Balance.cachedFloorRadius;
    final max = currentLevel + Balance.cachedFloorRadius;
    floors.removeWhere((level, _) => level < min || level > max);
  }

  void _loadNode(RoomNode node, {required Direction? entryDirection}) {
    _currentNode = node;
    node.visited = true;
    _roomVisitCount += 1;

    game.gameState.setFloor(currentLevel);
    game.gameState.setRoom(_roomVisitCount);
    game.gameState.setRoomType(node.type);
    game.gameState.setBossRoom(node.type == RoomType.boss);
    game.gameState.setRoomCleared(node.cleared);

    _currentRoom?.removeFromParent();
    _removeLooseCombatObjects();

    final room = Room(
      index: node.distanceFromStart + 1,
      node: node,
      manager: this,
    );
    _currentRoom = room;
    game.world.add(room);

    game.player.position = _spawnPositionFor(entryDirection, node.type);
    game.updateCameraBounds(room.bounds);
    game.juice.updateCamera(0);
    game.playBgmForCurrentRoom();
  }

  Vector2 _spawnPositionFor(Direction? entryDirection, RoomType type) {
    final size = Balance.roomSize(currentLevel);
    if (entryDirection == null) {
      return switch (type) {
        RoomType.start => Vector2(0, 74),
        RoomType.upstairs => Vector2(0, -74),
        _ => Vector2.zero(),
      };
    }

    // Must stay outside ExitDoor.activationDepth (measured from the door,
    // which sits Room.wallThickness / 2 inside the wall) or the player
    // spawns already inside the new room's entry-door trigger zone and
    // immediately bounces back through it.
    final horizontal = size.width / 2 - 130;
    final vertical = size.height / 2 - 130;
    return switch (entryDirection) {
      Direction.left => Vector2(-horizontal, 0),
      Direction.right => Vector2(horizontal, 0),
      Direction.up => Vector2(0, -vertical),
      Direction.down => Vector2(0, vertical),
    };
  }

  void _removeLooseCombatObjects() {
    final staleObjects = game.world.children.where(
      (component) =>
          component is Enemy ||
          component is Boss ||
          component is MiniBoss ||
          component is BossProjectile ||
          component is MiniBossProjectile ||
          component is EnemyProjectile ||
          component is Projectile,
    );

    for (final component in staleObjects.toList()) {
      component.removeFromParent();
    }
  }
}
