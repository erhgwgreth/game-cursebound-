import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'effects.dart';
import 'offscreen_threat.dart';
import 'room.dart';
import '../data/enemy_data.dart';
import '../game/cursebound_game.dart';
import '../systems/effect_sprite_cache.dart';

enum EnemyState { idle, chase, telegraph, attack, recover }

enum _TelegraphShape { line, circle, multiCircle }

class Enemy extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Enemy({
    required super.position,
    this.onDeath,
    this.onSpawnedEnemy,
    this.kind = EnemyKind.charger,
    this.eliteModifier = EliteModifier.none,
    this.healthMultiplier = 1,
    this.damage = contactDamage,
    this.speed = moveSpeed,
    this.splitDepth = 0,
    double? radius,
    Color? color,
  }) : super(
         radius:
             (radius ?? _radiusFor(kind)) *
             (eliteModifier == EliteModifier.none ? 1 : 1.15),
         anchor: Anchor.center,
         paint: Paint()
           ..color = color ?? _colorFor(kind, eliteModifier: eliteModifier),
       );

  static const double moveSpeed = 95;
  static const int contactDamage = 10;
  static const int maxHp = 30;
  static const double attackSpeedMultiplier = 2.5;
  static const double attackDuration = 0.18;
  static const double _wallPadding = 30;

  final void Function()? onDeath;
  final void Function()? onSpawnedEnemy;
  final EnemyKind kind;
  final EliteModifier eliteModifier;
  final double healthMultiplier;
  final int damage;
  final double speed;
  final int splitDepth;

  int hp = maxHp;
  int _maxHp = maxHp;
  EnemyState state = EnemyState.idle;
  double _stateTimeLeft = 0.25;
  double _attackCooldownLeft = 0.35;
  Vector2 _attackDirection = Vector2.zero();
  bool _hasDealtAttackDamage = false;
  bool _runicShieldReady = false;
  bool _hasResolvedDeath = false;
  int _remainingBurstAttacks = 0;
  int _shotsLeftInBurst = 0;
  double _burstShotCooldownLeft = 0;
  double _reflectCooldownLeft = 1.4;
  double _reflectLeft = 0;
  double _empoweredLeft = 0;
  double _slowLeft = 0;
  double _slowMultiplier = 1;
  List<Vector2> _artilleryTargets = [];
  Color _baseColor = const Color(0xFF7A7D86);
  double _flashLeft = 0;
  Vector2 _knockbackVelocity = Vector2.zero();
  _EnemyTelegraph? _telegraph;
  Sprite? _sprite;

  // Visual size only — the body/hitbox radius (_radiusFor above) is
  // untouched, so floating decorations in the art (Caster/Summoner orbs and
  // magic circles) extend past the hitbox instead of being included in it.
  static const double chargerSpriteSize = 64;
  static const double casterSpriteSize = 52;
  static const double bomberSpriteSize = 62;
  static const double wardenSpriteSize = 70;
  static const double hexerSpriteSize = 54;
  static const double mirrorWraithSpriteSize = 52;
  static const double artillerySpriteSize = 56;
  static const double summonerSpriteSize = 58;
  static const double splitterSpriteSize = 56;
  static const double acolyteSpriteSize = 54;

  String? get _spriteAsset {
    return switch (kind) {
      EnemyKind.charger => 'enemy_charger.png',
      EnemyKind.caster => 'enemy_caster.png',
      EnemyKind.bomber => 'enemy_bomber.png',
      EnemyKind.warden => 'enemy_warden.png',
      EnemyKind.hexer => 'enemy_hexer.png',
      EnemyKind.mirrorWraith => 'enemy_mirror.png',
      EnemyKind.artillery => 'enemy_artillery.png',
      EnemyKind.summoner => 'enemy_summoner.png',
      EnemyKind.splitter => 'enemy_splitter.png',
      EnemyKind.acolyte => 'enemy_acolyte.png',
    };
  }

  double get _spriteSize {
    return switch (kind) {
      EnemyKind.charger => chargerSpriteSize,
      EnemyKind.caster => casterSpriteSize,
      EnemyKind.bomber => bomberSpriteSize,
      EnemyKind.warden => wardenSpriteSize,
      EnemyKind.hexer => hexerSpriteSize,
      EnemyKind.mirrorWraith => mirrorWraithSpriteSize,
      EnemyKind.artillery => artillerySpriteSize,
      EnemyKind.summoner => summonerSpriteSize,
      EnemyKind.splitter => splitterSpriteSize,
      EnemyKind.acolyte => acolyteSpriteSize,
    };
  }

  int get _level => game.gameState.floor;

  EnemyAttackProfile get _profile => EnemyProfiles.forKind(kind);

  int get _effectiveDamage {
    return (damage * (_empoweredLeft > 0 ? 1.28 : 1)).round();
  }

  int get maxHpValue => _maxHp;

  double get _chargerAttackDuration {
    return (_profile.attackRadius(_level) /
            (_effectiveSpeed * attackSpeedMultiplier))
        .clamp(attackDuration, 0.62);
  }

  double get _chargerShockwaveRadius {
    return (96 + _level * 6).clamp(96, 168).toDouble();
  }

  double get _effectiveSpeed {
    final baseSpeed = speed == moveSpeed ? _profile.moveSpeed(_level) : speed;
    return baseSpeed *
        (eliteModifier == EliteModifier.gale ? 1.28 : 1) *
        _slowMultiplier;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final eliteHp = eliteModifier == EliteModifier.none ? 1.0 : 1.55;
    hp =
        (maxHp *
                healthMultiplier *
                eliteHp *
                game.gameState.stats.enemyHealthMultiplier)
            .round();
    _maxHp = hp;
    _runicShieldReady = eliteModifier == EliteModifier.runicShield;
    _baseColor = paint.color;
    final asset = _spriteAsset;
    if (asset != null) {
      _sprite = await _loadSpriteSafely(asset);
    }
    add(CircleHitbox());
    _enterState(EnemyState.chase);
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('Enemy sprite load failed ($path): $error');
      return null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_flashLeft > 0) {
      _flashLeft -= dt;
      if (_flashLeft <= 0) {
        paint.color = _baseColor;
      }
    }
    _updateMirrorReflect(dt);
    if (!_knockbackVelocity.isZero()) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity.scale(0.82);
      if (_knockbackVelocity.length2 < 16) {
        _knockbackVelocity.setZero();
      }
    }

    _attackCooldownLeft -= dt;
    _empoweredLeft = math.max(0, _empoweredLeft - dt);
    _slowLeft = math.max(0, _slowLeft - dt);
    if (_slowLeft <= 0) {
      _slowMultiplier = 1;
    }
    final toPlayer = game.player.position - position;
    final distanceToPlayer = toPlayer.length;
    final directionToPlayer = toPlayer.isZero()
        ? Vector2.zero()
        : toPlayer.normalized();

    switch (state) {
      case EnemyState.idle:
        _stateTimeLeft -= dt;
        if (_stateTimeLeft <= 0) {
          _enterState(EnemyState.chase);
        }
      case EnemyState.chase:
        _updateChase(dt, distanceToPlayer, directionToPlayer);
      case EnemyState.telegraph:
        _stateTimeLeft -= dt;
        _telegraph?.progress = 1 - (_stateTimeLeft / _telegraphDuration);
        _updateTelegraph(dt, directionToPlayer);
        if (_stateTimeLeft <= 0) {
          _enterState(EnemyState.attack);
        }
      case EnemyState.attack:
        _stateTimeLeft -= dt;
        _updateAttack(dt);
        if (_stateTimeLeft <= 0) {
          _enterState(EnemyState.recover);
        }
      case EnemyState.recover:
        _stateTimeLeft -= dt;
        if (_stateTimeLeft <= 0) {
          _enterState(EnemyState.chase);
        }
    }
    _clampInsideRoom();
  }

  void takeDamage(int amount, {Vector2? source}) {
    if (_runicShieldReady) {
      _runicShieldReady = false;
      parent?.add(
        HitSpark(
          position: position.clone(),
          color: const Color(0xFF8FA1C7),
          radius: 12,
        ),
      );
      return;
    }
    if (_reflectLeft > 0) {
      _reflectIncomingShot(amount, source: source);
      amount = (amount * 0.55).ceil();
    }

    hp -= amount;
    final killed = hp <= 0;
    if (eliteModifier == EliteModifier.thorns) {
      game.player.takeDamage(3);
    }
    game.audio.playHit();
    game.juice.enemyHit(
      this,
      damage: amount,
      killed: killed,
      critical: amount >= game.gameState.stats.attackDamage * 1.8,
      source: source,
    );
    if (killed) {
      if (kind == EnemyKind.bomber) {
        _explode(radius: 58, damage: (damage * 0.65).round());
      }
      if (kind == EnemyKind.splitter) {
        _splitOnDeath();
      }
      _resolveDeath(grantKillReward: true);
    }
  }

  void flash(Color color, {required double duration}) {
    paint.color = color;
    _flashLeft = duration;
  }

  void applyKnockback(Vector2 source, {required double strength}) {
    final direction = position - source;
    if (direction.isZero()) {
      return;
    }

    _knockbackVelocity += direction.normalized() * strength;
    if (_knockbackVelocity.length > 220) {
      _knockbackVelocity = _knockbackVelocity.normalized() * 220;
    }
  }

  void applySlow({required double multiplier, required double duration}) {
    _slowMultiplier = math.min(_slowMultiplier, multiplier.clamp(0.25, 1.0));
    _slowLeft = math.max(_slowLeft, duration);
    parent?.add(
      HitSpark(
        position: position.clone(),
        color: const Color(0xFF8FA1C7),
        radius: 9,
      ),
    );
  }

  void _updateChase(
    double dt,
    double distanceToPlayer,
    Vector2 directionToPlayer,
  ) {
    if (directionToPlayer.isZero()) {
      return;
    }

    if (_attackCooldownLeft <= 0 && _shouldAttack(distanceToPlayer)) {
      _attackDirection = directionToPlayer;
      _remainingBurstAttacks = _profile.burstCount(_level) - 1;
      _enterState(EnemyState.telegraph);
      return;
    }

    if (_isBacklineEnemy && distanceToPlayer < 190) {
      position -= directionToPlayer * _effectiveSpeed * 0.75 * dt;
    } else if (_isBacklineEnemy && distanceToPlayer < 310) {
      return;
    } else {
      position += directionToPlayer * _effectiveSpeed * dt;
    }
  }

  bool get _isBacklineEnemy {
    return kind == EnemyKind.caster ||
        kind == EnemyKind.artillery ||
        kind == EnemyKind.summoner ||
        kind == EnemyKind.acolyte;
  }

  bool _shouldAttack(double distanceToPlayer) {
    return switch (kind) {
      EnemyKind.charger =>
        distanceToPlayer <=
            (_profile.attackRadius(_level) * 0.72).clamp(120, 200),
      EnemyKind.caster => distanceToPlayer <= _profile.attackRadius(_level),
      EnemyKind.bomber => distanceToPlayer <= 92,
      EnemyKind.warden => distanceToPlayer <= 92,
      EnemyKind.hexer => distanceToPlayer <= 170,
      EnemyKind.mirrorWraith => distanceToPlayer <= 105,
      EnemyKind.artillery => distanceToPlayer <= 520,
      EnemyKind.summoner => distanceToPlayer <= 440,
      EnemyKind.splitter => distanceToPlayer <= _profile.attackRadius(_level),
      EnemyKind.acolyte => distanceToPlayer <= 460,
    };
  }

  void _updateTelegraph(double dt, Vector2 directionToPlayer) {
    if (kind != EnemyKind.bomber || directionToPlayer.isZero()) {
      return;
    }

    position += directionToPlayer * _effectiveSpeed * 1.18 * dt;
    _clampInsideRoom();
    _telegraph?.position = position.clone();
  }

  void _updateAttack(double dt) {
    switch (kind) {
      case EnemyKind.charger:
        position +=
            _attackDirection * _effectiveSpeed * attackSpeedMultiplier * dt;
        _tryDealTouchDamage(radius + game.player.size.x * 0.55);
      case EnemyKind.caster:
        _updateCasterBurst(dt);
      case EnemyKind.bomber:
        if (!_hasDealtAttackDamage) {
          final blastRadius = _profile.attackRadius(_level);
          _explode(radius: blastRadius, damage: _effectiveDamage + 6);
          if (_profile.hasPattern(_level, SubPattern.lingeringBlast)) {
            _leaveHazard(
              radius: blastRadius * 0.55,
              damage: (_effectiveDamage * 0.5).round(),
            );
          }
          if (_profile.hasPattern(_level, SubPattern.deathFragments)) {
            _spawnRadialShots(
              _profile.projectileCount(_level),
              damage: (_effectiveDamage * 0.55).round(),
            );
          }
          _hasDealtAttackDamage = true;
          _resolveDeath(grantKillReward: false);
        }
      case EnemyKind.warden:
        if (!_hasDealtAttackDamage) {
          final slamRadius = _profile.attackRadius(_level);
          _explode(radius: slamRadius, damage: _effectiveDamage);
          if (_profile.hasPattern(_level, SubPattern.shieldPush)) {
            _pushPlayer(strength: 240);
          }
          if (_profile.hasPattern(_level, SubPattern.shieldWave)) {
            _spawnFanShots(
              count: _profile.projectileCount(_level),
              spread: 0.62,
              damage: (_effectiveDamage * 0.65).round(),
            );
          }
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.hexer:
        if (!_hasDealtAttackDamage) {
          _explode(
            radius: _profile.attackRadius(_level),
            damage: _effectiveDamage,
          );
          _applyHexDebuff();
          if (_profile.hasPattern(_level, SubPattern.hexField)) {
            _leaveHazard(
              radius: _profile.attackRadius(_level) * 0.55,
              damage: (_effectiveDamage * 0.35).round(),
            );
          }
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.mirrorWraith:
        if (!_hasDealtAttackDamage) {
          _explode(
            radius: _profile.attackRadius(_level),
            damage: _effectiveDamage,
          );
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.artillery:
        if (!_hasDealtAttackDamage) {
          for (final target in _artilleryTargets) {
            _explodeAt(
              target,
              radius: _profile.attackRadius(_level),
              damage: _effectiveDamage,
            );
          }
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.summoner:
        if (!_hasDealtAttackDamage) {
          _summonMinion();
          if (_profile.hasPattern(_level, SubPattern.summonShield)) {
            _runicShieldReady = true;
          }
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.splitter:
        if (!_hasDealtAttackDamage) {
          if (splitDepth == 0 ||
              _profile.hasPattern(_level, SubPattern.aggressiveSplits)) {
            _explode(
              radius: _profile.attackRadius(_level),
              damage: _effectiveDamage,
            );
          }
          _hasDealtAttackDamage = true;
        }
      case EnemyKind.acolyte:
        if (!_hasDealtAttackDamage) {
          _healAndBlessAllies();
          _hasDealtAttackDamage = true;
        }
    }
  }

  double get _telegraphDuration {
    final base = _profile.telegraphTime(_level);
    final eliteSpeed = eliteModifier == EliteModifier.gale ? 0.78 : 1.0;
    return (base * eliteSpeed).clamp(0.36, 0.9);
  }

  void _enterState(EnemyState nextState) {
    state = nextState;
    switch (nextState) {
      case EnemyState.idle:
        _stateTimeLeft = 0.2;
      case EnemyState.chase:
        _stateTimeLeft = 0;
        opacity = 1;
      case EnemyState.telegraph:
        _stateTimeLeft = _telegraphDuration;
        opacity = 0.82;
        _hasDealtAttackDamage = false;
        _shotsLeftInBurst = 0;
        _prepareTelegraphTargets();
        _showTelegraph();
      case EnemyState.attack:
        _stateTimeLeft = switch (kind) {
          EnemyKind.charger => _chargerAttackDuration,
          EnemyKind.caster => _profile.burstCount(_level) >= 2 ? 0.44 : 0.12,
          EnemyKind.artillery => 0.12,
          EnemyKind.splitter =>
            _profile.hasPattern(_level, SubPattern.aggressiveSplits)
                ? 0.1
                : 0.04,
          EnemyKind.acolyte => 0.14,
          _ => 0.08,
        };
        opacity = 1;
        _removeTelegraph();
      case EnemyState.recover:
        if (_remainingBurstAttacks > 0 && kind == EnemyKind.charger) {
          _remainingBurstAttacks -= 1;
          final toPlayer = game.player.position - position;
          if (!toPlayer.isZero()) {
            _attackDirection = toPlayer.normalized();
          }
          _enterState(EnemyState.telegraph);
          return;
        }
        if (kind == EnemyKind.charger &&
            _profile.hasPattern(_level, SubPattern.impactShockwave)) {
          _explode(
            radius: _chargerShockwaveRadius,
            damage: (damage * 0.7).round(),
          );
        }
        if (kind == EnemyKind.caster &&
            _profile.hasPattern(_level, SubPattern.blinkAfterCast)) {
          _blinkAwayFromPlayer();
        }
        _attackCooldownLeft = switch (kind) {
          EnemyKind.charger => 0.75,
          EnemyKind.caster => _level >= 8 ? 0.95 : 1.15,
          EnemyKind.bomber => 999,
          EnemyKind.warden => 1.0,
          EnemyKind.hexer => 1.2,
          EnemyKind.mirrorWraith => 0.92,
          EnemyKind.artillery => _level >= 9 ? 1.05 : 1.35,
          EnemyKind.summoner => _level >= 7 ? 1.85 : 2.4,
          EnemyKind.splitter => 0.72,
          EnemyKind.acolyte => _level >= 13 ? 1.55 : 2.15,
        };
        _stateTimeLeft = switch (kind) {
          EnemyKind.charger => 0.48,
          EnemyKind.caster => 0.55,
          EnemyKind.bomber => 0,
          EnemyKind.warden => 0.7,
          EnemyKind.hexer => 0.55,
          EnemyKind.mirrorWraith => 0.42,
          EnemyKind.artillery => 0.48,
          EnemyKind.summoner => 0.78,
          EnemyKind.splitter => 0.32,
          EnemyKind.acolyte => 0.65,
        };
        opacity = 0.65;
    }
  }

  void _showTelegraph() {
    _removeTelegraph();
    final telegraph = switch (kind) {
      EnemyKind.charger => _EnemyTelegraph.line(
        position: position.clone(),
        direction: _attackDirection.clone(),
        length: _profile.attackRadius(_level) + radius,
        telegraphWidth: radius * 1.85,
      ),
      EnemyKind.caster => _EnemyTelegraph.line(
        position: position.clone(),
        direction: _attackDirection.clone(),
        length: 340,
        telegraphWidth: 10,
      ),
      EnemyKind.bomber => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.warden => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.hexer => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.mirrorWraith => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.artillery => _EnemyTelegraph.multiCircle(
        positions: _artilleryTargets,
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.summoner => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: 46,
      ),
      EnemyKind.splitter => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
      EnemyKind.acolyte => _EnemyTelegraph.circle(
        position: position.clone(),
        radius: _profile.attackRadius(_level),
      ),
    };
    _telegraph = telegraph;
    parent?.add(telegraph);
  }

  void _removeTelegraph() {
    _telegraph?.removeFromParent();
    _telegraph = null;
  }

  void _tryDealTouchDamage(double range) {
    if (_hasDealtAttackDamage) {
      return;
    }

    final toPlayer = game.player.position - position;
    if (toPlayer.length <= range) {
      game.player.takeDamage(damage, source: position.clone());
      _hasDealtAttackDamage = true;
    }
  }

  void _updateCasterBurst(double dt) {
    if (_shotsLeftInBurst <= 0 && !_hasDealtAttackDamage) {
      _shotsLeftInBurst = _profile.burstCount(_level);
      _burstShotCooldownLeft = 0;
    }
    if (_shotsLeftInBurst <= 0) {
      _hasDealtAttackDamage = true;
      return;
    }

    _burstShotCooldownLeft -= dt;
    if (_burstShotCooldownLeft > 0) {
      return;
    }

    _spawnFanShots(
      count: _profile.projectileCount(_level),
      spread: _level >= 7 ? 0.74 : 0.38,
      damage: damage,
    );
    _shotsLeftInBurst -= 1;
    _burstShotCooldownLeft = 0.16;
  }

  void _spawnFanShots({
    required int count,
    required double spread,
    required int damage,
  }) {
    if (count <= 1) {
      _spawnShot(direction: _attackDirection, damage: damage);
      return;
    }

    final startAngle = -spread / 2;
    final step = spread / (count - 1);
    for (var i = 0; i < count; i += 1) {
      final direction = _attackDirection.clone()..rotate(startAngle + step * i);
      _spawnShot(direction: direction, damage: damage);
    }
  }

  void _spawnShot({required Vector2 direction, required int damage}) {
    parent?.add(
      EnemyProjectile(
        position: position.clone(),
        direction: direction.clone(),
        damage: damage,
      ),
    );
  }

  void _reflectIncomingShot(int amount, {Vector2? source}) {
    final toPlayer = game.player.position - position;
    if (toPlayer.isZero()) {
      return;
    }

    final count = _profile.projectileCount(_level);
    final reflectedDamage = (amount * 0.3).ceil().clamp(4, 16);
    final spread = switch (count) {
      <= 1 => 0.0,
      2 || 3 => 0.42,
      _ => 0.78,
    };
    _attackDirection = toPlayer.normalized();
    _spawnFanShots(count: count, spread: spread, damage: reflectedDamage);
    parent?.add(
      HitSpark(
        position: source?.clone() ?? position.clone(),
        color: const Color(0xFFFFD166),
        radius: 12,
      ),
    );
  }

  void _explode({required double radius, required int damage}) {
    game.juice.explosion(position);
    if ((game.player.position - position).length <= radius) {
      game.player.takeDamage(damage, source: position.clone());
    }
  }

  void _explodeAt(
    Vector2 target, {
    required double radius,
    required int damage,
  }) {
    game.juice.explosion(target);
    if ((game.player.position - target).length <= radius) {
      game.player.takeDamage(damage, source: target.clone());
    }
  }

  void _applyHexDebuff() {
    final duration = _profile.hasPattern(_level, SubPattern.dualHex)
        ? 2.6
        : 1.6;
    final slow = _profile.hasPattern(_level, SubPattern.dualHex) ? 0.58 : 0.72;
    game.player.applySlow(multiplier: slow, duration: duration);
    parent?.add(
      HitSpark(
        position: game.player.position.clone(),
        color: const Color(0xFF7B2CBF),
        radius: 14,
      ),
    );
  }

  void _prepareTelegraphTargets() {
    if (kind != EnemyKind.artillery) {
      _artilleryTargets = [];
      return;
    }

    final count = _profile.projectileCount(_level);
    final base = game.player.position.clone();
    final targets = <Vector2>[base];
    if (count >= 3) {
      targets.addAll([base + Vector2(82, 0), base + Vector2(-82, 0)]);
    }
    if (count >= 4) {
      targets.add(base + Vector2(0, 82));
    }
    if (_profile.hasPattern(_level, SubPattern.trackingArtillery)) {
      targets[0] = game.player.position.clone();
    }
    _artilleryTargets = targets.map(_clampedRoomPoint).toList();
  }

  Vector2 _clampedRoomPoint(Vector2 point) {
    const inset = _wallPadding + 24;
    final roomSize =
        game.roomManager.currentRoom?.scaledRoomSize ?? Room.roomSize;
    final halfWidth = roomSize.x / 2;
    final halfHeight = roomSize.y / 2;
    return Vector2(
      point.x.clamp(-halfWidth + inset, halfWidth - inset).toDouble(),
      point.y.clamp(-halfHeight + inset, halfHeight - inset).toDouble(),
    );
  }

  void _summonMinion() {
    final summonKind = _profile.hasPattern(_level, SubPattern.mixedSummons)
        ? (math.Random(
                position.x.round() ^ position.y.round() ^ _level,
              ).nextBool()
              ? EnemyKind.caster
              : EnemyKind.bomber)
        : EnemyKind.charger;
    final offset = Vector2(46, 0)
      ..rotate(math.Random().nextDouble() * math.pi * 2);
    final spawnPosition = _clampedRoomPoint(position + offset);
    onSpawnedEnemy?.call();
    parent?.add(
      Enemy(
        position: spawnPosition,
        kind: summonKind,
        onDeath: onDeath,
        onSpawnedEnemy: onSpawnedEnemy,
        healthMultiplier: healthMultiplier * 0.45,
        damage: (damage * 0.65).round().clamp(1, 999),
        radius: 13,
        color: const Color(0xFF6F5661),
      ),
    );
    parent?.add(
      HitSpark(
        position: spawnPosition,
        color: const Color(0xFFD7B84F),
        radius: 12,
      ),
    );
  }

  void _splitOnDeath() {
    final maxDepth = _profile.hasPattern(_level, SubPattern.secondSplit)
        ? 2
        : 1;
    if (splitDepth >= maxDepth) {
      return;
    }

    final count = _level >= 15 ? 3 : 2;
    for (var i = 0; i < count; i += 1) {
      final angle = math.pi * 2 * i / count;
      final spawnPosition = _clampedRoomPoint(
        position + Vector2(math.cos(angle), math.sin(angle)) * 34,
      );
      onSpawnedEnemy?.call();
      parent?.add(
        Enemy(
          position: spawnPosition,
          kind: EnemyKind.splitter,
          splitDepth: splitDepth + 1,
          onDeath: onDeath,
          onSpawnedEnemy: onSpawnedEnemy,
          healthMultiplier: healthMultiplier * 0.52,
          damage: (damage * 0.68).round().clamp(1, 999),
          radius: (radius * 0.68).clamp(8, 18).toDouble(),
          color: const Color(0xFFAA6F73),
        ),
      );
    }
  }

  void _healAndBlessAllies() {
    final range = _profile.attackRadius(_level);
    final healAmount = (8 + _level * 1.8).round();
    var affected = 0;
    final allies =
        parent?.children.whereType<Enemy>() ?? const Iterable.empty();
    for (final ally in allies) {
      if (ally == this || !ally.isMounted || ally.hp <= 0) {
        continue;
      }
      if ((ally.position - position).length > range) {
        continue;
      }

      affected += 1;
      ally._receiveAcolyteHeal(healAmount);
      if (_profile.hasPattern(_level, SubPattern.attackBlessing)) {
        ally._receiveAcolyteBlessing();
      }
      if (!_profile.hasPattern(_level, SubPattern.areaHeal) && affected >= 1) {
        break;
      }
    }

    parent?.add(
      HitSpark(
        position: position.clone(),
        color: const Color(0xFF9FE870),
        radius: 16 + affected * 2,
      ),
    );
  }

  void _receiveAcolyteHeal(int amount) {
    hp = (hp + amount).clamp(1, _maxHp);
    flash(const Color(0xFF9FE870), duration: 0.12);
  }

  void _receiveAcolyteBlessing() {
    _empoweredLeft = math.max(_empoweredLeft, 3.2);
    parent?.add(
      HitSpark(
        position: position.clone(),
        color: const Color(0xFFD7B84F),
        radius: 10,
      ),
    );
  }

  void _updateMirrorReflect(double dt) {
    if (kind != EnemyKind.mirrorWraith) {
      return;
    }

    _reflectCooldownLeft -= dt;
    if (_reflectLeft > 0) {
      _reflectLeft -= dt;
      paint.color = const Color(0xFFFFD166);
      if (!_profile.hasPattern(_level, SubPattern.movingReflect)) {
        _knockbackVelocity.setZero();
      }
      if (_reflectLeft <= 0) {
        paint.color = _baseColor;
      }
      return;
    }
    if (_reflectCooldownLeft <= 0) {
      _reflectLeft = _level >= 8 ? 1.1 : 0.8;
      _reflectCooldownLeft = (_level >= 8 ? 2.2 : 3.0).clamp(1.4, 3.0);
    }
  }

  void _leaveHazard({required double radius, required int damage}) {
    parent?.add(
      _EnemyHazard(position: position.clone(), radius: radius, damage: damage),
    );
  }

  void _spawnRadialShots(int count, {required int damage}) {
    if (count <= 0) {
      return;
    }

    for (var i = 0; i < count; i += 1) {
      final angle = math.pi * 2 * i / count;
      _spawnShot(
        direction: Vector2(math.cos(angle), math.sin(angle)),
        damage: damage,
      );
    }
  }

  void _pushPlayer({required double strength}) {
    final toPlayer = game.player.position - position;
    if (toPlayer.isZero()) {
      return;
    }

    game.player.position += toPlayer.normalized() * (strength * 0.08);
  }

  void _blinkAwayFromPlayer() {
    final away = position - game.player.position;
    if (away.isZero()) {
      return;
    }

    position += away.normalized() * 90;
    _clampInsideRoom();
    parent?.add(
      HitSpark(
        position: position.clone(),
        color: const Color(0xFF7E89A8),
        radius: 10,
      ),
    );
  }

  void _clampInsideRoom() {
    final inset = _wallPadding + radius;
    final roomSize =
        game.roomManager.currentRoom?.scaledRoomSize ?? Room.roomSize;
    final halfWidth = roomSize.x / 2;
    final halfHeight = roomSize.y / 2;
    position.x = position.x.clamp(-halfWidth + inset, halfWidth - inset);
    position.y = position.y.clamp(-halfHeight + inset, halfHeight - inset);
  }

  void _resolveDeath({required bool grantKillReward}) {
    if (_hasResolvedDeath) {
      return;
    }

    _hasResolvedDeath = true;
    if (grantKillReward) {
      game.notifyEnemyKilled(this);
    }
    onDeath?.call();
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);
    } else {
      final size = _spriteSize;
      sprite.render(
        canvas,
        position: Vector2.all(radius - size / 2),
        size: Vector2.all(size),
      );
    }

    if (eliteModifier != EliteModifier.none) {
      final auraPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFD7B84F).withValues(alpha: 0.72);
      canvas.drawCircle(Offset(radius, radius), radius + 5, auraPaint);
    }

    if (_runicShieldReady) {
      final shieldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF8FA1C7);
      canvas.drawCircle(Offset(radius, radius), radius + 9, shieldPaint);
    }
  }

  @override
  void onRemove() {
    _removeTelegraph();
    super.onRemove();
  }

  static double _radiusFor(EnemyKind kind) {
    return switch (kind) {
      EnemyKind.charger => 18,
      EnemyKind.caster => 16,
      EnemyKind.bomber => 20,
      EnemyKind.warden => 23,
      EnemyKind.hexer => 18,
      EnemyKind.mirrorWraith => 17,
      EnemyKind.artillery => 19,
      EnemyKind.summoner => 21,
      EnemyKind.splitter => 20,
      EnemyKind.acolyte => 18,
    };
  }

  static Color _colorFor(
    EnemyKind kind, {
    required EliteModifier eliteModifier,
  }) {
    if (eliteModifier != EliteModifier.none) {
      return const Color(0xFF9B8190);
    }
    return switch (kind) {
      EnemyKind.charger => const Color(0xFF7A7D86),
      EnemyKind.caster => const Color(0xFF7E89A8),
      EnemyKind.bomber => const Color(0xFF8F4B5B),
      EnemyKind.warden => const Color(0xFF6F6A58),
      EnemyKind.hexer => const Color(0xFF7B2CBF),
      EnemyKind.mirrorWraith => const Color(0xFFB8B8D1),
      EnemyKind.artillery => const Color(0xFFB5651D),
      EnemyKind.summoner => const Color(0xFF5E7D5A),
      EnemyKind.splitter => const Color(0xFFAA6F73),
      EnemyKind.acolyte => const Color(0xFF9FE870),
    };
  }
}

class EnemyProjectile extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame>, OffscreenThreat {
  EnemyProjectile({
    required super.position,
    required Vector2 direction,
    required this.damage,
  }) : _direction = direction.normalized(),
       super(
         radius: 6,
         anchor: Anchor.center,
         priority: 80,
         paint: Paint()..color = const Color(0xFFB11238),
       );

  static const double spriteSize = 34;

  final Vector2 _direction;
  final int damage;
  double _lifeLeft = 2.0;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await EffectSpriteCache.load(game, 'enemy_bolt.png');
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _direction * 260 * dt;
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
      game.player.takeDamage(damage, source: position.clone());
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      super.render(canvas);
      return;
    }

    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(_angleForDirection(_direction));
    sprite.render(
      canvas,
      position: Vector2.all(-spriteSize / 2),
      size: Vector2.all(spriteSize),
    );
    canvas.restore();
  }

  double _angleForDirection(Vector2 direction) {
    return math.atan2(direction.y, direction.x) + math.pi / 2;
  }
}

class _EnemyHazard extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  _EnemyHazard({
    required super.position,
    required double radius,
    required this.damage,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         priority: -4,
         paint: Paint()
           ..color = const Color(0xFFB11238).withValues(alpha: 0.22),
       );

  final int damage;
  double _lifeLeft = 1.8;
  double _damageCooldownLeft = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeLeft -= dt;
    _damageCooldownLeft -= dt;
    opacity = (_lifeLeft / 1.8).clamp(0.0, 1.0);
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other == game.player && _damageCooldownLeft <= 0) {
      game.player.takeDamage(damage, source: position.clone());
      _damageCooldownLeft = 0.45;
    }
  }
}

class _EnemyTelegraph extends PositionComponent
    with HasGameReference<CurseboundGame>, OffscreenThreat {
  _EnemyTelegraph.line({
    required super.position,
    required Vector2 direction,
    required this.length,
    required this.telegraphWidth,
  }) : shape = _TelegraphShape.line,
       radius = 0,
       positions = const [],
       _direction = direction.normalized(),
       super(anchor: Anchor.center, priority: -5);

  _EnemyTelegraph.circle({required super.position, required this.radius})
    : shape = _TelegraphShape.circle,
      length = 0,
      telegraphWidth = 0,
      positions = const [],
      _direction = Vector2.zero(),
      super(anchor: Anchor.center, priority: -5);

  _EnemyTelegraph.multiCircle({required this.positions, required this.radius})
    : shape = _TelegraphShape.multiCircle,
      length = 0,
      telegraphWidth = 0,
      _direction = Vector2.zero(),
      super(position: Vector2.zero(), anchor: Anchor.center, priority: -5);

  final _TelegraphShape shape;
  final Vector2 _direction;
  final double length;
  final double telegraphWidth;
  final double radius;
  final List<Vector2> positions;
  double progress = 0;
  Sprite? _circleSprite;
  Sprite? _lineSprite;
  Sprite? _lineLongSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    switch (shape) {
      case _TelegraphShape.line:
        _lineSprite = await EffectSpriteCache.load(game, 'telegraph_line.png');
        _lineLongSprite = await EffectSpriteCache.load(
          game,
          'telegraph_line_long.png',
        );
      case _TelegraphShape.circle:
      case _TelegraphShape.multiCircle:
        _circleSprite = await EffectSpriteCache.load(
          game,
          'telegraph_circle.png',
        );
    }
  }

  @override
  double get threatUrgency => 0.78 + progress * 0.14;

  @override
  List<Vector2> get threatPositions {
    return shape == _TelegraphShape.multiCircle ? positions : [position];
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse = (progress * 7).floor().isEven ? 0.35 : 0.7;
    final alpha = (0.2 + progress * 0.45 + pulse * 0.15).clamp(0.2, 0.9);
    final paint = Paint()
      ..color = const Color(0xFFB11238).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = const Color(0xFFFF5A76).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (shape) {
      case _TelegraphShape.line:
        if (_renderLineSprite(canvas, alpha)) {
          return;
        }
        final angle = math.atan2(_direction.y, _direction.x);
        canvas
          ..save()
          ..rotate(angle);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, -telegraphWidth / 2, length, telegraphWidth),
          Radius.circular(telegraphWidth / 2),
        );
        canvas
          ..drawRRect(rect, paint)
          ..drawRRect(rect, outlinePaint);

        final arrowPath = Path()
          ..moveTo(length + 14, 0)
          ..lineTo(length - 8, -telegraphWidth * 0.7)
          ..lineTo(length - 8, telegraphWidth * 0.7)
          ..close();
        canvas.drawPath(arrowPath, paint);
        canvas.restore();
      case _TelegraphShape.circle:
        if (_renderCircleSprite(canvas, Offset.zero, radius, alpha)) {
          return;
        }
        canvas
          ..drawCircle(Offset.zero, radius, paint)
          ..drawCircle(Offset.zero, radius, outlinePaint);
      case _TelegraphShape.multiCircle:
        for (final position in positions) {
          if (_renderCircleSprite(
            canvas,
            Offset(position.x, position.y),
            radius,
            alpha,
          )) {
            continue;
          }
          canvas
            ..drawCircle(Offset(position.x, position.y), radius, paint)
            ..drawCircle(Offset(position.x, position.y), radius, outlinePaint);
        }
    }
  }

  bool _renderLineSprite(Canvas canvas, double alpha) {
    final sprite = length > 300 ? _lineLongSprite ?? _lineSprite : _lineSprite;
    if (sprite == null) {
      return false;
    }

    final angle = math.atan2(_direction.y, _direction.x);
    canvas
      ..save()
      ..rotate(angle);
    sprite.render(
      canvas,
      position: Vector2(0, -telegraphWidth),
      size: Vector2(length, telegraphWidth * 2),
      overridePaint: Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 0.62)),
    );
    canvas.restore();
    return true;
  }

  bool _renderCircleSprite(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    final sprite = _circleSprite;
    if (sprite == null) {
      return false;
    }

    final size = radius * 2;
    sprite.render(
      canvas,
      position: Vector2(center.dx - radius, center.dy - radius),
      size: Vector2.all(size),
      overridePaint: Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 0.62)),
    );
    return true;
  }
}
