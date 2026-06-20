import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';

class OfferingAltar extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  OfferingAltar({required super.position})
    : super(
        radius: 28,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF3C1420),
      );

  double _openCooldownLeft = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _openCooldownLeft -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFFD7B84F);
    final bloodPaint = Paint()..color = const Color(0xFFB11238);
    canvas
      ..drawCircle(Offset(radius, radius), radius - 3, rimPaint)
      ..drawCircle(Offset(radius, radius), 8, bloodPaint);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other == game.player && _openCooldownLeft <= 0) {
      _openCooldownLeft = 1;
      game.openMerchant();
    }
  }
}
