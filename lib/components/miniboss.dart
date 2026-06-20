import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../data/balance.dart';
import '../game/cursebound_game.dart';
import 'offscreen_threat.dart';

class MiniBoss extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  MiniBoss({required super.position, required this.onDeath})
    : super(
        radius: 34,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF8E445A),
      );

  static const int baseHp = 135;
  static const int contactDamage = 14;

  final void Function() onDeath;

  late int hp;
  late int maxHp;
  double _contactCooldownLeft = 0;
  double _patternCooldownLeft = 0.8;
  double _telegraphLeft = 0;
  double _slamLeft = 0;
  double _flashLeft = 0;
  bool _deathResolved = false;
  Vector2 _slamDirection = Vector2.zero();
  Vector2 _knockbackVelocity = Vector2.zero();
  Color _baseColor = const Color(0xFF8E445A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    maxHp =
        (baseHp *
                Balance.enemyHealthScale(
                  floor: game.gameState.floor,
                  room: game.gameState.room,
                ) *
                game.gameState.stats.enemyHealthMultiplier)
            .round();
    hp = maxHp;
    _baseColor = paint.color;
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    _contactCooldownLeft -= dt;
    _patternCooldownLeft -= dt;
    if (_flashLeft > 0) {
      _flashLeft -= dt;
      if (_flashLeft <= 0) {
        paint.color = _baseColor;
      }
    }
    if (!_knockbackVelocity.isZero()) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity.scale(0.84);
      if (_knockbackVelocity.length2 < 16) {
        _knockbackVelocity.setZero();
      }
    }

    final toPlayer = game.player.position - position;
    final direction = toPlayer.isZero()
        ? Vector2.zero()
        : toPlayer.normalized();

    if (_telegraphLeft > 0) {
      _telegraphLeft -= dt;
      opacity = 0.65 + math.sin(_telegraphLeft * 48).abs() * 0.25;
      if (_telegraphLeft <= 0) {
        opacity = 1;
        _slamLeft = 0.32;
      }
      return;
    }

    if (_slamLeft > 0) {
      _slamLeft -= dt;
      position += _slamDirection * 330 * dt;
      if (_slamLeft <= 0) {
        _fireRing();
        _patternCooldownLeft = 1.25;
      }
      return;
    }

    if (!direction.isZero()) {
      position += direction * 72 * dt;
    }
    if (_patternCooldownLeft <= 0 && !direction.isZero()) {
      _slamDirection = direction;
      _telegraphLeft = 0.62;
      _patternCooldownLeft = 999;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other == game.player && _contactCooldownLeft <= 0) {
      game.player.takeDamage(contactDamage, source: position.clone());
      _contactCooldownLeft = 0.72;
    }
  }

  void takeDamage(int amount, {Vector2? source}) {
    hp -= amount;
    final killed = hp <= 0;
    game.audio.playHit();
    game.juice.bossHit(this, damage: amount, killed: killed, source: source);
    if (source != null) {
      _applyKnockback(source, strength: killed ? 80 : 34);
    }
    paint.color = const Color(0xFFFFFFFF);
    _flashLeft = 0.075;
    if (killed) {
      _resolveDeath();
    }
  }

  void _fireRing() {
    const count = 8;
    for (var i = 0; i < count; i += 1) {
      final angle = math.pi * 2 * i / count;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      parent?.add(
        MiniBossProjectile(position: position.clone(), direction: direction),
      );
    }
    game.juice.explosion(position);
  }

  void _resolveDeath() {
    if (_deathResolved) {
      return;
    }

    _deathResolved = true;
    game.gameState.addKill();
    onDeath();
    removeFromParent();
  }

  void _applyKnockback(Vector2 source, {required double strength}) {
    final direction = position - source;
    if (direction.isZero()) {
      return;
    }

    _knockbackVelocity += direction.normalized() * strength;
    if (_knockbackVelocity.length > 110) {
      _knockbackVelocity = _knockbackVelocity.normalized() * 110;
    }
  }
}

class MiniBossProjectile extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame>, OffscreenThreat {
  MiniBossProjectile({required super.position, required Vector2 direction})
    : _direction = direction.normalized(),
      super(
        radius: 6,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFD7B84F),
      );

  final Vector2 _direction;
  double _lifeLeft = 1.6;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _direction * 230 * dt;
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

    if (other == game.player) {
      game.player.takeDamage(11, source: position.clone());
      removeFromParent();
    }
  }
}
