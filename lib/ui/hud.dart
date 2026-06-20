import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/enemy.dart';
import '../components/offscreen_threat.dart';
import '../data/dungeon_map.dart';
import '../data/room_type.dart';
import '../game/cursebound_game.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.gameState,
      builder: (context, _) {
        final state = game.gameState;
        final curseCount = state.curses.length;
        final hasConflict = state.buildReport.conflicts.isNotEmpty;
        final hasSynergy = state.buildReport.synergies.isNotEmpty;

        return Stack(
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: _CurseVeilPainter(
                  curseCount: curseCount,
                  hasConflict: hasConflict,
                  hasSynergy: hasSynergy,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            _ThreatIndicatorLayer(game: game),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 18,
                                value: state.hpRatio,
                                backgroundColor: const Color(0xFF2A1118),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFEDEDED),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'HP ${state.hp}/${state.maxHp}   Essence ${state.essence}   Floor ${state.floor}   Room ${state.room} ${state.roomType.label}   Kills ${state.kills}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Curses ${state.curses.length}   DMG ${state.stats.attackDamage.toStringAsFixed(0)}   ASPD ${state.stats.attackSpeed.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (state.relic != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Relic ${state.relic!.name}',
                              style: const TextStyle(
                                color: Color(0xFFD7B84F),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (state.bossFavorActive) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Boss Favor active: essence x${state.bossFavorEssenceMultiplier.toStringAsFixed(1)} until you take stairs',
                              style: const TextStyle(
                                color: Color(0xFFD7B84F),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          if (state.revivalUnlocked) ...[
                            const SizedBox(height: 4),
                            Text(
                              state.revivalUsed
                                  ? 'Revival spent'
                                  : 'Revival ready: half HP + random curse on death',
                              style: TextStyle(
                                color: state.revivalUsed
                                    ? Colors.white38
                                    : const Color(0xFFFF5A76),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Juice ${game.juice.settings.enabled ? "ON" : "OFF"}   Shake ${game.juice.settings.screenShakeEnabled ? "ON" : "OFF"}   Tab/B Build   Esc Pause',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (state.buildReport.synergies.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final synergy
                                    in state.buildReport.synergies)
                                  _BuildChip(
                                    label: synergy.name,
                                    color: const Color(0xFFD7B84F),
                                  ),
                              ],
                            ),
                          ],
                          if (state.buildReport.conflicts.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final conflict
                                    in state.buildReport.conflicts)
                                  _BuildChip(
                                    label:
                                        '${conflict.name} x${state.buildReport.scoreMultiplier.toStringAsFixed(1)} score',
                                    color: const Color(0xFFB11238),
                                  ),
                              ],
                            ),
                          ],
                          if (state.isBossRoom && !state.isRoomCleared) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Boss room. The boss attacks faster as curses pile up.',
                              style: TextStyle(
                                color: Color(0xFFFF5A76),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (state.isRoomCleared) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Room cleared. Touch the altar for a pact, then use an open door.',
                              style: TextStyle(
                                color: Color(0xFFD7B84F),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (state.isGameOver) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Dead. Result screen arrives in Phase 6.',
                              style: TextStyle(
                                color: Color(0xFFFF5A76),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: _MiniMap(game: game),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.game});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    final current = game.roomManager.currentNode;
    if (current == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF08090D).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: SizedBox(
        width: 172,
        height: 132,
        child: CustomPaint(
          painter: _MiniMapPainter(
            nodes: game.roomManager.dungeon.nodes.values.toList(),
            current: current,
          ),
        ),
      ),
    );
  }
}

class _ThreatIndicatorLayer extends StatefulWidget {
  const _ThreatIndicatorLayer({required this.game});

  final CurseboundGame game;

  @override
  State<_ThreatIndicatorLayer> createState() => _ThreatIndicatorLayerState();
}

class _ThreatIndicatorLayerState extends State<_ThreatIndicatorLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
          )
          ..addListener(() => setState(() {}))
          ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.game.juice.settings.enabled ||
        !widget.game.juice.settings.offscreenIndicatorsEnabled) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: _ThreatIndicatorPainter(
          threats: _collectThreats(),
          playerPosition: widget.game.player.position,
          pulse: _pulse.value,
          intensity: widget.game.juice.settings.offscreenIndicatorIntensity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  List<_ThreatInfo> _collectThreats() {
    final roomChildren =
        widget.game.roomManager.currentRoom?.children.toList() ??
        const <Component>[];
    final components = <Component>[
      ...widget.game.world.children,
      ...roomChildren,
    ];
    final threats = <_ThreatInfo>[];
    for (final component in components) {
      if (component is! PositionComponent || !component.isMounted) {
        continue;
      }

      final urgency = switch (component) {
        OffscreenThreat() => component.threatUrgency,
        Enemy(state: EnemyState.telegraph) => 0.72,
        _ => 0.0,
      };
      if (urgency <= 0) {
        continue;
      }

      final positions = component is OffscreenThreat
          ? component.threatPositions
          : [component.position];
      for (final position in positions) {
        threats.add(_ThreatInfo(position: position.clone(), urgency: urgency));
      }
    }

    threats.sort((a, b) => b.urgency.compareTo(a.urgency));
    return threats.take(6).toList(growable: false);
  }
}

class _ThreatInfo {
  const _ThreatInfo({required this.position, required this.urgency});

  final Vector2 position;
  final double urgency;
}

class _ThreatIndicatorPainter extends CustomPainter {
  const _ThreatIndicatorPainter({
    required this.threats,
    required this.playerPosition,
    required this.pulse,
    required this.intensity,
  });

  static const double _viewWidth = 960;
  static const double _viewHeight = 540;

  final List<_ThreatInfo> threats;
  final Vector2 playerPosition;
  final double pulse;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (threats.isEmpty) {
      return;
    }

    final halfView = Vector2(_viewWidth / 2 - 28, _viewHeight / 2 - 28);
    final center = Offset(size.width / 2, size.height / 2);
    final edgePadding = 28.0;
    var drawn = 0;

    for (final threat in threats) {
      final relative = threat.position - playerPosition;
      if (relative.x.abs() <= halfView.x && relative.y.abs() <= halfView.y) {
        continue;
      }
      if (relative.isZero()) {
        continue;
      }

      final angle = math.atan2(relative.y, relative.x);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final edgeScale = math.min(
        (size.width / 2 - edgePadding) / direction.dx.abs().clamp(0.001, 1.0),
        (size.height / 2 - edgePadding) / direction.dy.abs().clamp(0.001, 1.0),
      );
      final position = center + direction * edgeScale;
      final blink = (math.sin((pulse * math.pi * 2) + drawn) + 1) / 2;
      final alpha =
          (0.38 + blink * 0.38 + threat.urgency * 0.2) *
          intensity.clamp(0.0, 1.5);
      final markerSize = 13 + threat.urgency * 10;
      final paint = Paint()
        ..color = const Color(
          0xFFFF5A76,
        ).withValues(alpha: alpha.clamp(0.0, 0.95))
        ..style = PaintingStyle.fill;
      final outline = Paint()
        ..color = const Color(0xFF08090D).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(angle);
      final path = Path()
        ..moveTo(markerSize, 0)
        ..lineTo(-markerSize * 0.58, -markerSize * 0.62)
        ..lineTo(-markerSize * 0.25, 0)
        ..lineTo(-markerSize * 0.58, markerSize * 0.62)
        ..close();
      canvas
        ..drawPath(path, paint)
        ..drawPath(path, outline)
        ..restore();

      drawn += 1;
      if (drawn >= 6) {
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_ThreatIndicatorPainter oldDelegate) {
    return threats != oldDelegate.threats ||
        playerPosition != oldDelegate.playerPosition ||
        pulse != oldDelegate.pulse ||
        intensity != oldDelegate.intensity;
  }
}

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({required this.nodes, required this.current});

  final List<RoomNode> nodes;
  final RoomNode current;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = <RoomNode>{};
    for (final node in nodes) {
      if (node.visited) {
        visible.add(node);
        for (final direction in node.exits) {
          final neighbor = _nodeAt(
            node.x + direction.dx,
            node.y + direction.dy,
          );
          if (neighbor != null) {
            visible.add(neighbor);
          }
        }
      }
    }

    if (visible.isEmpty) {
      return;
    }

    final minX = visible.map((node) => node.x).reduce((a, b) => a < b ? a : b);
    final maxX = visible.map((node) => node.x).reduce((a, b) => a > b ? a : b);
    final minY = visible.map((node) => node.y).reduce((a, b) => a < b ? a : b);
    final maxY = visible.map((node) => node.y).reduce((a, b) => a > b ? a : b);
    final spanX = (maxX - minX + 1).clamp(1, 99);
    final spanY = (maxY - minY + 1).clamp(1, 99);
    final cell = (size.width / (spanX + 1))
        .clamp(14.0, size.height / (spanY + 1))
        .clamp(10.0, 20.0);
    final origin = Offset(
      (size.width - spanX * cell) / 2,
      (size.height - spanY * cell) / 2,
    );

    Offset centerFor(RoomNode node) {
      return origin +
          Offset((node.x - minX + 0.5) * cell, (node.y - minY + 0.5) * cell);
    }

    final connectionPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    for (final node in visible.where((node) => node.visited)) {
      for (final direction in node.exits) {
        final neighbor = _nodeAt(node.x + direction.dx, node.y + direction.dy);
        if (neighbor == null || !visible.contains(neighbor)) {
          continue;
        }
        canvas.drawLine(centerFor(node), centerFor(neighbor), connectionPaint);
      }
    }

    for (final node in visible) {
      final rect = Rect.fromCenter(
        center: centerFor(node),
        width: cell * 0.72,
        height: cell * 0.72,
      );
      final visited = node.visited;
      final isCurrent = node == current;
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = visited
            ? _colorFor(node.type).withValues(alpha: 0.86)
            : Colors.transparent;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2.8 : 1.4
        ..color = isCurrent
            ? const Color(0xFFD7B84F)
            : visited
            ? Colors.white70
            : Colors.white30;

      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          fill,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          stroke,
        );

      if (visited) {
        _drawLabel(canvas, rect.center, _labelFor(node.type), cell);
      }
    }
  }

  RoomNode? _nodeAt(int x, int y) {
    for (final node in nodes) {
      if (node.x == x && node.y == y) {
        return node;
      }
    }
    return null;
  }

  void _drawLabel(Canvas canvas, Offset center, String label, double cell) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFF08090D),
          fontSize: cell * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  Color _colorFor(RoomType type) {
    return switch (type) {
      RoomType.start => const Color(0xFF8FA1C7),
      RoomType.normal => const Color(0xFFEDEDED),
      RoomType.treasure || RoomType.miniboss => const Color(0xFFD7B84F),
      RoomType.elite => const Color(0xFFFF5A76),
      RoomType.challenge => const Color(0xFFB11238),
      RoomType.merchant ||
      RoomType.offering ||
      RoomType.upstairs => const Color(0xFF8FA1C7),
      RoomType.boss => const Color(0xFFD7B84F),
    };
  }

  String _labelFor(RoomType type) {
    return switch (type) {
      RoomType.start => 'S',
      RoomType.normal => '',
      RoomType.treasure => 'T',
      RoomType.miniboss => 'M',
      RoomType.elite => 'E',
      RoomType.challenge => 'C',
      RoomType.merchant => 'O',
      RoomType.offering => 'O',
      RoomType.upstairs => 'U',
      RoomType.boss => 'B',
    };
  }

  @override
  bool shouldRepaint(_MiniMapPainter oldDelegate) {
    return current != oldDelegate.current || nodes != oldDelegate.nodes;
  }
}

class _CurseVeilPainter extends CustomPainter {
  const _CurseVeilPainter({
    required this.curseCount,
    required this.hasConflict,
    required this.hasSynergy,
  });

  final int curseCount;
  final bool hasConflict;
  final bool hasSynergy;

  @override
  void paint(Canvas canvas, Size size) {
    if (curseCount <= 0 && !hasConflict && !hasSynergy) {
      return;
    }

    final stage = (curseCount / 8).clamp(0.0, 1.0);
    final edgeAlpha = (0.16 + stage * 0.34 + (hasConflict ? 0.1 : 0)).clamp(
      0.0,
      0.62,
    );
    final crimson = hasConflict
        ? const Color(0xFFB11238)
        : const Color(0xFF4D0718);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * (0.48 - stage * 0.06);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          crimson.withValues(alpha: edgeAlpha * 0.38),
          const Color(0xFF050407).withValues(alpha: edgeAlpha),
        ],
        stops: const [0.48, 0.78, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + stage * 10
      ..color = crimson.withValues(alpha: 0.08 + stage * 0.16);
    canvas.drawRect(Offset.zero & size, borderPaint);

    if (hasSynergy) {
      final goldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD7B84F).withValues(alpha: 0.16);
      canvas.drawCircle(center, radius, goldPaint);
    }

    if (hasConflict) {
      final warningPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFF5A76).withValues(alpha: 0.22);
      canvas.drawCircle(center, radius * 0.88, warningPaint);
    }
  }

  @override
  bool shouldRepaint(_CurseVeilPainter oldDelegate) {
    return curseCount != oldDelegate.curseCount ||
        hasConflict != oldDelegate.hasConflict ||
        hasSynergy != oldDelegate.hasSynergy;
  }
}

class _BuildChip extends StatelessWidget {
  const _BuildChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
