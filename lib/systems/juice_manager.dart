import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../components/enemy.dart';
import '../components/effects.dart';
import '../game/cursebound_game.dart';

class JuiceSettings {
  bool enabled = true;
  bool screenShakeEnabled = true;
  bool offscreenIndicatorsEnabled = true;
  double screenShakeIntensity = 1;
  double hitStopIntensity = 1;
  double offscreenIndicatorIntensity = 1;
}

class JuiceManager {
  JuiceManager(this.game);

  final CurseboundGame game;
  final JuiceSettings settings = JuiceSettings();
  final Random _random = Random();

  double _shakeTimeLeft = 0;
  double _shakeDuration = 0;
  double _shakeStrength = 0;
  double _hitStopLeft = 0;

  bool get isHitStopping => settings.enabled && _hitStopLeft > 0;

  void updateHitStop(double dt) {
    if (_hitStopLeft > 0) {
      _hitStopLeft -= dt;
    }
  }

  void updateCamera(double dt) {
    var offset = Vector2.zero();
    if (settings.enabled &&
        settings.screenShakeEnabled &&
        _shakeTimeLeft > 0 &&
        _shakeDuration > 0) {
      final trauma = (_shakeTimeLeft / _shakeDuration).clamp(0, 1).toDouble();
      final amount =
          _shakeStrength * trauma * trauma * settings.screenShakeIntensity;
      offset = Vector2(
        (_random.nextDouble() * 2 - 1) * amount,
        (_random.nextDouble() * 2 - 1) * amount,
      );
      _shakeTimeLeft -= dt;
      if (_shakeTimeLeft <= 0) {
        _shakeStrength = 0;
        _shakeDuration = 0;
      }
    }

    game.camera.viewfinder.position = game.clampCameraPosition(
      game.player.position + offset,
    );
  }

  void enemyHit(
    Enemy enemy, {
    required int damage,
    required bool killed,
    bool critical = false,
    Vector2? source,
  }) {
    if (!settings.enabled) {
      return;
    }

    _hitStop(killed ? 0.065 : 0.035);
    _shake(strength: killed ? 5 : 2.4, duration: killed ? 0.12 : 0.08);
    _spawnSpark(
      enemy.position.clone(),
      color: critical ? const Color(0xFFFFF2A6) : const Color(0xFFD7B84F),
      radius: killed ? 12 : 8,
    );
    _spawnBurst(
      enemy.position.clone(),
      color: critical ? const Color(0xFFFFF2A6) : const Color(0xFFD7B84F),
      count: killed ? 14 : 7,
      speed: killed ? 145 : 95,
    );
    _spawnDamageNumber(
      enemy.position.clone() + Vector2(0, -enemy.radius - 8),
      text: critical ? '$damage!' : '$damage',
      color: critical ? const Color(0xFFFFF2A6) : const Color(0xFFEDEDED),
      scale: critical ? 1.28 : 1,
    );
    enemy.flash(
      critical ? const Color(0xFFFFF2A6) : const Color(0xFFFFFFFF),
      duration: killed ? 0.12 : 0.075,
    );
    if (source != null) {
      enemy.applyKnockback(source, strength: killed ? 150 : 75);
    }
  }

  void bossHit(
    PositionComponent boss, {
    required int damage,
    required bool killed,
    Vector2? source,
  }) {
    if (!settings.enabled) {
      return;
    }

    _hitStop(killed ? 0.08 : 0.045);
    _shake(strength: killed ? 14 : 4, duration: killed ? 0.28 : 0.1);
    _spawnSpark(
      boss.position.clone(),
      color: killed ? const Color(0xFFB11238) : const Color(0xFFD7B84F),
      radius: killed ? 26 : 14,
    );
    _spawnBurst(
      boss.position.clone(),
      color: killed ? const Color(0xFFB11238) : const Color(0xFFD7B84F),
      count: killed ? 28 : 10,
      speed: killed ? 180 : 100,
    );
    _spawnDamageNumber(
      boss.position.clone() + Vector2(0, -44),
      text: '$damage',
      color: const Color(0xFFFFF2A6),
      scale: 1.2,
    );
  }

  void playerHit(Vector2 position, {required int damage}) {
    if (!settings.enabled) {
      return;
    }

    _shake(strength: 10, duration: 0.18);
    _spawnSpark(position.clone(), color: const Color(0xFFB11238), radius: 12);
    _spawnBurst(
      position.clone(),
      color: const Color(0xFFB11238),
      count: 9,
      speed: 120,
    );
    _spawnDamageNumber(
      position.clone() + Vector2(0, -30),
      text: '-$damage',
      color: const Color(0xFFFF5A76),
      scale: 1.1,
    );
  }

  void explosion(Vector2 position) {
    if (!settings.enabled) {
      return;
    }

    _shake(strength: 12, duration: 0.22);
    game.world.add(ExplosionAnimationEffect(position: position.clone()));
    _spawnSpark(position.clone(), color: const Color(0xFFB11238), radius: 20);
    _spawnBurst(
      position.clone(),
      color: const Color(0xFFFF5A76),
      count: 22,
      speed: 190,
    );
  }

  void impact({required double strength, required double duration}) {
    if (!settings.enabled) {
      return;
    }

    _shake(strength: strength, duration: duration);
  }

  void phaseTransition(Vector2 position) {
    if (!settings.enabled) {
      return;
    }

    _hitStop(0.075);
    _shake(strength: 16, duration: 0.35);
    _spawnSpark(position.clone(), color: const Color(0xFFB11238), radius: 28);
    _spawnBurst(
      position.clone(),
      color: const Color(0xFFB11238),
      count: 34,
      speed: 210,
    );
  }

  void dash({
    required Vector2 start,
    required Vector2 end,
    required Vector2 direction,
  }) {
    if (!settings.enabled) {
      return;
    }

    game.world.add(
      OneShotSpriteEffect(
        position: start.clone(),
        assetName: 'dash_bust_effect.png',
        startSize: 66,
        endSize: 112,
        life: 0.22,
        startOpacity: 0.9,
        priority: 35,
      ),
    );
    final dashAngle = atan2(direction.y, direction.x) + pi / 2;
    final trailPositions = [start, (start + end) / 2, end];
    for (var i = 0; i < trailPositions.length; i += 1) {
      game.world.add(
        OneShotSpriteEffect(
          position: trailPositions[i].clone(),
          assetName: 'dash_effect.png',
          startSize: 82 - i * 8,
          endSize: 102 - i * 6,
          life: 0.24 - i * 0.035,
          startOpacity: 0.72 - i * 0.12,
          effectAngle: dashAngle,
          priority: 34,
        ),
      );
    }
    _spawnSpark(start.clone(), color: const Color(0xFFEDEDED), radius: 10);
  }

  void contractAccepted(Vector2 position) {
    if (!settings.enabled) {
      return;
    }

    _hitStop(0.055);
    _shake(strength: 6, duration: 0.18);
    _spawnBurst(
      position.clone() + Vector2(-18, 0),
      color: const Color(0xFFD7B84F),
      count: 16,
      speed: 125,
    );
    _spawnBurst(
      position.clone() + Vector2(18, 0),
      color: const Color(0xFFB11238),
      count: 16,
      speed: 125,
    );
  }

  void blessingAcquired(Vector2 position) {
    if (!settings.enabled) {
      return;
    }

    game.world.add(
      OneShotSpriteEffect(
        position: position.clone(),
        assetName: 'blessing_glow.png',
        startSize: 72,
        endSize: 126,
        life: 0.42,
        startOpacity: 0.88,
      ),
    );
    _spawnBurst(
      position.clone(),
      color: const Color(0xFFD7B84F),
      count: 14,
      speed: 110,
    );
  }

  void curseAcquired(Vector2 position) {
    if (!settings.enabled) {
      return;
    }

    _shake(strength: 4, duration: 0.12);
    _spawnBurst(
      position.clone(),
      color: const Color(0xFFB11238),
      count: 14,
      speed: 120,
    );
  }

  void buildShift({
    required Vector2 position,
    required bool synergyActivated,
    required bool conflictActivated,
  }) {
    if (!settings.enabled || (!synergyActivated && !conflictActivated)) {
      return;
    }

    if (synergyActivated) {
      _hitStop(0.045);
      _shake(strength: 5, duration: 0.14);
      _spawnBurst(
        position.clone(),
        color: const Color(0xFFD7B84F),
        count: 24,
        speed: 150,
      );
    }

    if (conflictActivated) {
      _hitStop(0.065);
      _shake(strength: 11, duration: 0.22);
      _spawnSpark(position.clone(), color: const Color(0xFFB11238), radius: 24);
      _spawnBurst(
        position.clone(),
        color: const Color(0xFFFF5A76),
        count: 30,
        speed: 190,
      );
    }
  }

  void _hitStop(double duration) {
    _hitStopLeft = max(_hitStopLeft, duration * settings.hitStopIntensity);
    _hitStopLeft = _hitStopLeft.clamp(0, 0.09).toDouble();
  }

  void _shake({required double strength, required double duration}) {
    _shakeStrength = max(_shakeStrength, strength).clamp(0, 18).toDouble();
    _shakeDuration = max(_shakeDuration, duration).clamp(0, 0.35).toDouble();
    _shakeTimeLeft = max(_shakeTimeLeft, duration).clamp(0, 0.35).toDouble();
  }

  void _spawnSpark(
    Vector2 position, {
    required Color color,
    required double radius,
  }) {
    game.world.add(HitSpark(position: position, color: color, radius: radius));
  }

  void _spawnBurst(
    Vector2 position, {
    required Color color,
    required int count,
    required double speed,
  }) {
    for (var i = 0; i < count; i += 1) {
      final angle = _random.nextDouble() * pi * 2;
      final velocity =
          Vector2(cos(angle), sin(angle)) *
          (speed * (0.45 + _random.nextDouble() * 0.65));
      game.world.add(
        BurstParticle(
          position: position.clone(),
          velocity: velocity,
          color: color,
          radius: 2.5 + _random.nextDouble() * 3.2,
          life: 0.24 + _random.nextDouble() * 0.18,
        ),
      );
    }
  }

  void _spawnDamageNumber(
    Vector2 position, {
    required String text,
    required Color color,
    required double scale,
  }) {
    game.world.add(
      FloatingText(
        position: position,
        text: text,
        color: color,
        textScale: scale,
      ),
    );
  }
}
