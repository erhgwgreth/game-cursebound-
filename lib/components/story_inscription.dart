import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../data/story_fragment.dart';
import '../game/cursebound_game.dart';

class StoryInscription extends RectangleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  StoryInscription({required super.position, required this.fragment})
    : super(
        size: Vector2(54, 34),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF6F2A3A),
      );

  // Visual size only — the hitbox above stays 54x34 for the E-key trigger.
  static const double spriteSize = 64;

  final StoryFragment fragment;
  bool _isNearby = false;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await _loadSpriteSafely('inscription.png');
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('StoryInscription sprite load failed ($path): $error');
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);
      final rune = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD7B84F).withValues(alpha: 0.82);
      canvas
        ..drawLine(const Offset(12, 8), const Offset(42, 26), rune)
        ..drawLine(const Offset(42, 8), const Offset(12, 26), rune)
        ..drawCircle(const Offset(27, 17), 8, rune);
      return;
    }

    sprite.render(
      canvas,
      position: size / 2 - Vector2.all(spriteSize / 2),
      size: Vector2.all(spriteSize),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (!_isNearby && other == game.player) {
      _isNearby = true;
      paint.color = const Color(0xFF8A3A4F);
      game.setNearbyInscription(fragment);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other == game.player) {
      _isNearby = false;
      if (game.nearbyInscriptionFragment?.id == fragment.id) {
        game.setNearbyInscription(null);
      }
      paint.color = const Color(0xFF6F2A3A);
    }
  }
}
