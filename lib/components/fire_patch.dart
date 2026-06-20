import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/cursebound_game.dart';
import 'boss.dart';
import 'enemy.dart';
import 'miniboss.dart';

class FirePatch extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  FirePatch({
    required super.position,
    double radius = 18,
    this.damage = 8,
    this.lifeTime = 1.1,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         paint: Paint()
           ..color = const Color(0xFFB11238).withValues(alpha: 0.45),
       );

  final Set<int> _burnedTargets = {};
  final int damage;
  final double lifeTime;
  late double _lifeLeft = lifeTime;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeLeft -= dt;
    final progress = (1 - _lifeLeft / lifeTime).clamp(0, 1).toDouble();
    paint.color = const Color(
      0xFFB11238,
    ).withValues(alpha: (0.45 * (1 - progress)).clamp(0, 0.45));

    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    final targetId = identityHashCode(other);
    if (_burnedTargets.contains(targetId)) {
      return;
    }

    if (other is Enemy) {
      _burnedTargets.add(targetId);
      other.takeDamage(damage);
    } else if (other is Boss) {
      _burnedTargets.add(targetId);
      other.takeDamage(damage);
    } else if (other is MiniBoss) {
      _burnedTargets.add(targetId);
      other.takeDamage(damage);
    }
  }
}
