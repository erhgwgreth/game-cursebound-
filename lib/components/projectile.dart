import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'boss.dart';
import 'enemy.dart';
import 'fire_patch.dart';
import 'miniboss.dart';
import '../game/cursebound_game.dart';

class Projectile extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Projectile({
    required super.position,
    required Vector2 direction,
    this.damage = 30,
    this.speed = 520,
    this.leavesFire = false,
    this.pierce = 0,
    this.chainCount = 0,
    this.chainRange = 180,
    this.executeThreshold = 0,
    double radius = 6,
  }) : _direction = direction.normalized(),
       super(
         radius: radius,
         anchor: Anchor.center,
         paint: Paint()..color = const Color(0xFFE7D27B),
       );

  static const double maxLifetime = 1.4;

  final Vector2 _direction;
  final int damage;
  final double speed;
  final bool leavesFire;
  final int pierce;
  final int chainCount;
  final double chainRange;
  final double executeThreshold;
  final Set<int> _hitTargets = {};
  double _lifeLeft = maxLifetime;
  double _fireTrailCooldownLeft = 0;
  late int _remainingPierce = pierce;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += _direction * speed * dt;
    if (leavesFire) {
      _fireTrailCooldownLeft -= dt;
      if (_fireTrailCooldownLeft <= 0) {
        parent?.add(FirePatch(position: position.clone()));
        _fireTrailCooldownLeft = 0.16;
      }
    }

    _lifeLeft -= dt;
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
    if (_hitTargets.contains(targetId)) {
      return;
    }

    if (other is Enemy) {
      _hitTargets.add(targetId);
      final hitDamage = _damageForEnemy(other);
      other.takeDamage(hitDamage, source: position.clone());
      _tryChainFrom(other.position);
      _consumePierce();
    } else if (other is Boss) {
      _hitTargets.add(targetId);
      other.takeDamage(damage, source: position.clone());
      _tryChainFrom(other.position);
      _consumePierce();
    } else if (other is MiniBoss) {
      _hitTargets.add(targetId);
      other.takeDamage(damage, source: position.clone());
      _tryChainFrom(other.position);
      _consumePierce();
    }
  }

  int _damageForEnemy(Enemy enemy) {
    if (executeThreshold > 0 &&
        enemy.maxHpValue > 0 &&
        enemy.hp / enemy.maxHpValue <= executeThreshold) {
      return enemy.hp;
    }
    return damage;
  }

  void _consumePierce() {
    if (_remainingPierce > 0) {
      _remainingPierce -= 1;
      return;
    }
    removeFromParent();
  }

  void _tryChainFrom(Vector2 source) {
    if (chainCount <= 0) {
      return;
    }

    PositionComponent? bestTarget;
    var bestDistance = chainRange;
    final candidates = [
      ...game.world.children,
      ...?game.roomManager.currentRoom?.children,
    ];
    for (final component in candidates) {
      if (component is! PositionComponent) {
        continue;
      }
      if (_hitTargets.contains(identityHashCode(component))) {
        continue;
      }
      final isValidTarget =
          component is Enemy || component is Boss || component is MiniBoss;
      if (!isValidTarget || !component.isMounted) {
        continue;
      }
      final distance = (component.position - source).length;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestTarget = component;
      }
    }

    if (bestTarget == null) {
      return;
    }

    final direction = bestTarget.position - source;
    if (direction.isZero()) {
      return;
    }

    game.world.add(
      Projectile(
        position: source.clone(),
        direction: direction,
        damage: (damage * 0.78).round().clamp(1, 999),
        speed: speed * 1.08,
        leavesFire: leavesFire,
        pierce: 0,
        chainCount: chainCount - 1,
        chainRange: chainRange,
        executeThreshold: executeThreshold,
        radius: radius * 0.9,
      ),
    );
  }
}
