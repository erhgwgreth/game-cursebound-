import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';

class Altar extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Altar({required super.position})
    : super(
        radius: 28,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFE5C85A),
      );

  bool _isActivated = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.passive);
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
