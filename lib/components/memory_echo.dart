import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';

class MemoryEcho extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  MemoryEcho({required super.position})
    : super(
        radius: 34,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFD7B84F).withValues(alpha: 0.7),
      );

  bool _opened = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFB11238).withValues(alpha: 0.8);
    canvas
      ..drawCircle(Offset(radius, radius), radius + 8, ring)
      ..drawCircle(Offset(radius, radius), radius * 0.45, ring);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (!_opened && other == game.player) {
      _opened = true;
      game.openMemoryRoom();
    }
  }
}
