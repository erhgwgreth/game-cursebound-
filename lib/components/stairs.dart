import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';

class Stairs extends RectangleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Stairs.up({required super.position})
    : isUp = true,
      super(
        size: Vector2(58, 42),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFD7B84F),
      );

  Stairs.down({required super.position})
    : isUp = false,
      super(
        size: Vector2(58, 42),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF8FA1C7),
      );

  final bool isUp;
  double _useCooldownLeft = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _useCooldownLeft -= dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final linePaint = Paint()
      ..color = const Color(0xFF08090D)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i += 1) {
      final y = 12.0 + i * 9;
      canvas.drawLine(Offset(10, y), Offset(size.x - 10, y), linePaint);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other == game.player && _useCooldownLeft <= 0) {
      _useCooldownLeft = 1;
      if (isUp) {
        game.roomManager.goUpstairs();
      } else {
        game.roomManager.goDownstairs();
      }
    }
  }
}
