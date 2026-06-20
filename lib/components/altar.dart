import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../game/cursebound_game.dart';

class Altar extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Altar({required super.position})
    : super(
        radius: 28,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFE5C85A),
      );

  static const double spriteSize = 168;

  bool _isActivated = false;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await _loadSpriteSafely('altar_contract.png');
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('Altar sprite load failed ($path): $error');
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);
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

    if (!_isActivated && other == game.player) {
      _isActivated = true;
      paint.color = const Color(0xFF8C7B38);
      game.addTrauma(strength: 8, duration: 0.24);
      game.openContract();
    }
  }
}
