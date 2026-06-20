import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

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

  final StoryFragment fragment;
  bool _isNearby = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rune = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD7B84F).withValues(alpha: 0.82);
    canvas
      ..drawLine(const Offset(12, 8), const Offset(42, 26), rune)
      ..drawLine(const Offset(42, 8), const Offset(12, 26), rune)
      ..drawCircle(const Offset(27, 17), 8, rune);
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
