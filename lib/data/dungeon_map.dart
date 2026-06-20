import 'dart:collection';
import 'dart:math';

import 'balance.dart';
import 'room_type.dart';

enum Direction { up, down, left, right }

extension DirectionVector on Direction {
  int get dx {
    return switch (this) {
      Direction.left => -1,
      Direction.right => 1,
      _ => 0,
    };
  }

  int get dy {
    return switch (this) {
      Direction.up => -1,
      Direction.down => 1,
      _ => 0,
    };
  }

  Direction get opposite {
    return switch (this) {
      Direction.up => Direction.down,
      Direction.down => Direction.up,
      Direction.left => Direction.right,
      Direction.right => Direction.left,
    };
  }
}

class RoomNode {
  RoomNode({required this.x, required this.y, this.type = RoomType.normal});

  final int x;
  final int y;
  RoomType type;
  bool cleared = false;
  bool visited = false;
  bool pactRewardPending = false;
  bool memoryRewardClaimed = false;
  int distanceFromStart = 0;
  final Set<Direction> exits = {};

  String get key => keyFor(x, y);

  bool get isCombatRoom {
    return switch (type) {
      RoomType.start ||
      RoomType.merchant ||
      RoomType.offering ||
      RoomType.upstairs ||
      RoomType.memory => false,
      _ => true,
    };
  }

  static String keyFor(int x, int y) => '$x,$y';
}

class DungeonMap {
  DungeonMap({
    required this.seed,
    required this.nodes,
    required this.start,
    required this.upstairs,
  });

  final int seed;
  final Map<String, RoomNode> nodes;
  final RoomNode start;
  final RoomNode upstairs;

  RoomNode? nodeAt(int x, int y) => nodes[RoomNode.keyFor(x, y)];

  RoomNode? neighbor(RoomNode node, Direction direction) {
    return nodeAt(node.x + direction.dx, node.y + direction.dy);
  }

  static DungeonMap generate({
    required int seed,
    required int floor,
    int targetRooms = 12,
  }) {
    final random = Random(seed);
    final nodes = <String, RoomNode>{};
    final start = RoomNode(x: 0, y: 0, type: RoomType.start)..cleared = true;
    nodes[start.key] = start;

    var current = start;
    var attempts = 0;
    while (nodes.length < targetRooms && attempts < targetRooms * 80) {
      attempts += 1;
      final directions = [...Direction.values]..shuffle(random);
      final shouldBranch = random.nextDouble() < 0.34;
      if (shouldBranch) {
        current = nodes.values.elementAt(random.nextInt(nodes.length));
      }

      for (final direction in directions) {
        final x = current.x + direction.dx;
        final y = current.y + direction.dy;
        final key = RoomNode.keyFor(x, y);
        if (nodes.containsKey(key)) {
          current.exits.add(direction);
          nodes[key]!.exits.add(direction.opposite);
          current = nodes[key]!;
          break;
        }

        final node = RoomNode(x: x, y: y);
        nodes[key] = node;
        current.exits.add(direction);
        node.exits.add(direction.opposite);
        current = node;
        break;
      }
    }

    _assignDistances(start, nodes);
    final upstairs = _assignRoomTypes(start, nodes, random, floor);
    return DungeonMap(
      seed: seed,
      nodes: nodes,
      start: start,
      upstairs: upstairs,
    );
  }

  static void _assignDistances(RoomNode start, Map<String, RoomNode> nodes) {
    final queue = Queue<RoomNode>()..add(start);
    final visited = <String>{start.key};
    start.distanceFromStart = 0;

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      for (final direction in node.exits) {
        final neighbor =
            nodes[RoomNode.keyFor(
              node.x + direction.dx,
              node.y + direction.dy,
            )];
        if (neighbor == null || visited.contains(neighbor.key)) {
          continue;
        }
        neighbor.distanceFromStart = node.distanceFromStart + 1;
        visited.add(neighbor.key);
        queue.add(neighbor);
      }
    }
  }

  static RoomNode _assignRoomTypes(
    RoomNode start,
    Map<String, RoomNode> nodes,
    Random random,
    int floor,
  ) {
    final candidates = nodes.values.where((node) => node != start).toList();
    final deadEnds = candidates.where((node) => node.exits.length == 1).toList()
      ..sort((a, b) => b.distanceFromStart.compareTo(a.distanceFromStart));

    final boss = deadEnds.isNotEmpty
        ? deadEnds.first
        : (candidates..sort(
                (a, b) => b.distanceFromStart.compareTo(a.distanceFromStart),
              ))
              .first;
    boss.type = RoomType.boss;

    final upstairs = deadEnds.firstWhere(
      (node) => node != boss,
      orElse: () => candidates.firstWhere((node) => node != boss),
    );
    upstairs
      ..type = RoomType.upstairs
      ..cleared = true;

    final specialPool = candidates
        .where((node) => node != boss && node != upstairs)
        .toList();
    final preferred = [
      ...deadEnds.where((node) => node != boss && node != upstairs),
      ...specialPool..shuffle(random),
    ];
    final specialTypes = Balance.specialRoomTypesForFloor(floor);

    var specialIndex = 0;
    final used = <String>{boss.key, upstairs.key};
    for (final node in preferred) {
      if (specialIndex >= specialTypes.length || used.contains(node.key)) {
        continue;
      }
      node.type = specialTypes[specialIndex];
      used.add(node.key);
      specialIndex += 1;
    }
    return upstairs;
  }
}

class DungeonFloor {
  const DungeonFloor({
    required this.level,
    required this.seed,
    required this.map,
  });

  final int level;
  final int seed;
  final DungeonMap map;
}
