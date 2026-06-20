import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'boss.dart';
import 'enemy.dart';
import 'fire_patch.dart';
import 'miniboss.dart';
import '../game/cursebound_game.dart';

class Player extends RectangleComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<CurseboundGame> {
  Player({required super.position})
    : super(
        size: Vector2.all(32),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFFFFFF),
      );

  static const double invincibleDuration = 0.2;

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Vector2 _lastMoveDirection = Vector2(1, 0);
  double _dashCooldownLeft = 0;
  double _invincibleLeft = 0;
  double _pulseTime = 0;
  double _speedBuffLeft = 0;
  double _speedBuffMultiplier = 1;
  double _slowLeft = 0;
  double _slowMultiplier = 1;
  double _flashLeft = 0;
  double _auraTickCooldownLeft = 0;
  double _aegisCooldownLeft = 0;
  bool _aegisReady = false;
  Vector2 _knockbackVelocity = Vector2.zero();
  bool _isMoving = false;

  bool get isInvincible => _invincibleLeft > 0;

  bool get isMoving => _isMoving;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    handleKeyboard(event, keysPressed);
    return true;
  }

  void handleKeyboard(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys
      ..clear()
      ..addAll(keysPressed);

    if (event is KeyDownEvent && _isDashKey(event.logicalKey)) {
      _tryDash();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _pulseTime += dt;
    _dashCooldownLeft = math.max(0, _dashCooldownLeft - dt);
    _invincibleLeft = math.max(0, _invincibleLeft - dt);
    _speedBuffLeft = math.max(0, _speedBuffLeft - dt);
    _slowLeft = math.max(0, _slowLeft - dt);
    _flashLeft = math.max(0, _flashLeft - dt);
    _auraTickCooldownLeft = math.max(0, _auraTickCooldownLeft - dt);
    _updateAegis(dt);
    if (_speedBuffLeft <= 0) {
      _speedBuffMultiplier = 1;
    }
    if (_slowLeft <= 0) {
      _slowMultiplier = 1;
    }
    if (!_knockbackVelocity.isZero()) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity.scale(0.8);
      if (_knockbackVelocity.length2 < 16) {
        _knockbackVelocity.setZero();
      }
    }

    final direction = _movementDirection();
    _isMoving = !direction.isZero();
    if (!direction.isZero()) {
      _lastMoveDirection = direction.normalized();
      position +=
          _lastMoveDirection *
          game.gameState.stats.moveSpeed *
          game.gameState.stats.movingMoveSpeedMultiplier *
          _speedBuffMultiplier *
          _slowMultiplier *
          dt;
    }
    _updateAura();

    opacity = _invincibleLeft > 0 ? 0.55 : 1;
    paint.color = _flashLeft > 0
        ? const Color(0xFFFF5A76)
        : const Color(0xFFFFFFFF);
  }

  @override
  void render(Canvas canvas) {
    final curseCount = game.gameState.curses.length;
    final curseStage = (curseCount / 8).clamp(0.0, 1.0);

    if (curseCount > 0) {
      final pulse = (math.sin(_pulseTime * 6) + 1) * 0.5;
      final auraAlpha = (0.08 + curseCount * 0.03 + pulse * 0.07).clamp(
        0.08,
        0.38,
      );
      final auraPaint = Paint()
        ..color = const Color(0xFFB11238).withValues(alpha: auraAlpha);
      canvas.drawRect(
        Rect.fromLTWH(
          -8 - curseStage * 8,
          -8 - curseStage * 8,
          size.x + 16 + curseStage * 16,
          size.y + 16 + curseStage * 16,
        ),
        auraPaint,
      );
    }

    super.render(canvas);

    if (curseCount > 0) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2 + curseCount * 0.42).clamp(2, 6).toDouble()
        ..color = const Color(0xFFB11238).withValues(alpha: 0.85);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), strokePaint);

      if (curseCount >= 3) {
        final crackPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFFF5A76).withValues(alpha: 0.45);
        canvas
          ..drawLine(
            Offset(size.x * 0.28, size.y * 0.1),
            Offset(size.x * 0.55, size.y * 0.48),
            crackPaint,
          )
          ..drawLine(
            Offset(size.x * 0.55, size.y * 0.48),
            Offset(size.x * 0.42, size.y * 0.9),
            crackPaint,
          );
      }
    }
  }

  Vector2 _movementDirection() {
    final direction = Vector2.zero();

    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }

    return direction.isZero() ? direction : direction.normalized();
  }

  void _tryDash() {
    if (_dashCooldownLeft > 0) {
      return;
    }

    final start = position.clone();
    position += _lastMoveDirection * game.gameState.stats.dashDistance;
    if (game.gameState.stats.dashLeavesFire) {
      _leaveDashFire(start, position.clone());
    }
    _dashCooldownLeft = game.gameState.stats.dashCooldown;
    _invincibleLeft = game.gameState.stats.dashInvincibleDuration;
    game.juice.dash(position);
  }

  bool _isDashKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight;
  }

  void takeDamage(int amount, {Vector2? source}) {
    if (isInvincible) {
      return;
    }
    if (_aegisReady) {
      _aegisReady = false;
      _aegisCooldownLeft = game.gameState.stats.aegisCooldown;
      game.juice.blessingAcquired(position);
      return;
    }

    game.notifyPlayerHit(amount.toDouble());
    game.gameState.takeDamage(amount, playerMoving: isMoving);
    _invincibleLeft = invincibleDuration;
    _flashLeft = 0.12;
    if (source != null) {
      _applyKnockback(source, strength: 160);
    }
    _triggerSlowField();
    game.juice.playerHit(position, damage: amount);
  }

  void grantInvincibility(double duration) {
    _invincibleLeft = math.max(_invincibleLeft, duration);
  }

  void grantSpeedBuff({required double multiplier, required double duration}) {
    _speedBuffMultiplier = math.max(_speedBuffMultiplier, multiplier);
    _speedBuffLeft = math.max(_speedBuffLeft, duration);
  }

  void applySlow({required double multiplier, required double duration}) {
    _slowMultiplier = math.min(_slowMultiplier, multiplier.clamp(0.25, 1.0));
    _slowLeft = math.max(_slowLeft, duration);
  }

  void _leaveDashFire(Vector2 start, Vector2 end) {
    const patches = 5;
    final stats = game.gameState.stats;
    for (var i = 0; i < patches; i += 1) {
      final t = i / (patches - 1);
      game.world.add(
        FirePatch(
          position: start + (end - start) * t,
          radius: stats.dashFireRadius,
          damage: stats.dashFireDamage.round(),
          lifeTime: 1.25,
        ),
      );
    }
  }

  void _updateAura() {
    final auraDamage = game.gameState.stats.auraDamage;
    if (auraDamage <= 0 || _auraTickCooldownLeft > 0) {
      return;
    }

    final radius = game.gameState.stats.auraRadius;
    var hitAny = false;
    for (final component in _nearbyComponents()) {
      if (component is Enemy &&
          (component.position - position).length <= radius) {
        component.takeDamage(auraDamage.round(), source: position.clone());
        hitAny = true;
      } else if (component is Boss &&
          (component.position - position).length <= radius) {
        component.takeDamage(auraDamage.round(), source: position.clone());
        hitAny = true;
      } else if (component is MiniBoss &&
          (component.position - position).length <= radius) {
        component.takeDamage(auraDamage.round(), source: position.clone());
        hitAny = true;
      }
    }
    if (hitAny) {
      game.world.add(
        _PlayerAuraPulse(position: position.clone(), radius: radius),
      );
    }
    _auraTickCooldownLeft = 0.45;
  }

  void _updateAegis(double dt) {
    final cooldown = game.gameState.stats.aegisCooldown;
    if (cooldown <= 0) {
      _aegisReady = false;
      _aegisCooldownLeft = 0;
      return;
    }
    if (_aegisReady) {
      return;
    }
    _aegisCooldownLeft -= dt;
    if (_aegisCooldownLeft <= 0) {
      _aegisReady = true;
    }
  }

  void _triggerSlowField() {
    final stats = game.gameState.stats;
    if (stats.slowFieldDuration <= 0 || stats.slowFieldStrength >= 1) {
      return;
    }
    const radius = 120.0;
    for (final component in _nearbyComponents()) {
      if (component is Enemy &&
          (component.position - position).length <= radius) {
        component.applySlow(
          multiplier: stats.slowFieldStrength,
          duration: stats.slowFieldDuration,
        );
      }
    }
    game.world.add(
      _PlayerAuraPulse(
        position: position.clone(),
        radius: radius,
        color: const Color(0xFF8FA1C7),
      ),
    );
  }

  void _applyKnockback(Vector2 source, {required double strength}) {
    final direction = position - source;
    if (direction.isZero()) {
      return;
    }

    _knockbackVelocity += direction.normalized() * strength;
    if (_knockbackVelocity.length > 210) {
      _knockbackVelocity = _knockbackVelocity.normalized() * 210;
    }
  }

  List<Component> _nearbyComponents() {
    return [...game.world.children, ...?game.roomManager.currentRoom?.children];
  }
}

class _PlayerAuraPulse extends CircleComponent {
  _PlayerAuraPulse({
    required super.position,
    required double radius,
    Color color = const Color(0xFFB11238),
  }) : _color = color,
       super(
         radius: radius,
         anchor: Anchor.center,
         priority: -2,
         paint: Paint()
           ..style = PaintingStyle.stroke
           ..strokeWidth = 3
           ..color = color.withValues(alpha: 0.72),
       );

  final Color _color;
  double _lifeLeft = 0.22;

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    paint.color = _color.withValues(
      alpha: (0.72 * (_lifeLeft / 0.22)).clamp(0.0, 0.72),
    );
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }
}
