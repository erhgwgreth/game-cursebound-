import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/cursebound_game.dart';

class MemoryEcho extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  MemoryEcho({required super.position})
    : super(
        radius: 34,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFD7B84F).withValues(alpha: 0.7),
      );

  // Visual size only — the body/hitbox radius above stays 34 for collision.
  static const double spriteSize = 168;

  bool _opened = false;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await _loadSpriteSafely('memory_shrine.png');
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('MemoryEcho sprite load failed ($path): $error');
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB11238).withValues(alpha: 0.8);
      canvas
        ..drawCircle(Offset(radius, radius), radius + 8, ring)
        ..drawCircle(Offset(radius, radius), radius * 0.45, ring);
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

    if (!_opened && other == game.player) {
      _opened = true;
      game.openMemoryRoom();
    }
  }
}
