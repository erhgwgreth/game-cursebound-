import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/cursebound_game.dart';

class OfferingAltar extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  OfferingAltar({required super.position})
    : super(
        radius: 28,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF3C1420),
      );

  static const double spriteSize = 168;

  double _openCooldownLeft = 0;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await _loadSpriteSafely('altar_offering.png');
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('Offering altar sprite load failed ($path): $error');
      return null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _openCooldownLeft -= dt;
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);

      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFFD7B84F);
      final bloodPaint = Paint()..color = const Color(0xFFB11238);
      canvas
        ..drawCircle(Offset(radius, radius), radius - 3, rimPaint)
        ..drawCircle(Offset(radius, radius), 8, bloodPaint);
      return;
    }

    sprite.render(
      canvas,
      position: Vector2.all(radius - spriteSize / 2),
      size: Vector2.all(spriteSize),
    );
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
