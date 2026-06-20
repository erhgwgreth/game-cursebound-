import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'effects.dart';
import 'enemy.dart';
import '../data/balance.dart';
import '../data/enemy_data.dart';
import '../data/game_modifier.dart';
import '../game/cursebound_game.dart';
import 'offscreen_threat.dart';
import 'room.dart';

class BossContext {
  const BossContext(this.boss);

  final Boss boss;
}

enum BossArchetype { crimsonVanguard, voidMaw, covenantHost }

extension BossArchetypeInfo on BossArchetype {
  String get name {
    return switch (this) {
      BossArchetype.crimsonVanguard => 'Crimson Vanguard',
      BossArchetype.voidMaw => 'Void Maw',
      BossArchetype.covenantHost => 'Covenant Host',
    };
  }

  Color get color {
    return switch (this) {
      BossArchetype.crimsonVanguard => const Color(0xFF8E445A),
      BossArchetype.voidMaw => const Color(0xFF5C3B8E),
      BossArchetype.covenantHost => const Color(0xFF6F6341),
    };
  }

  String get spriteAsset {
    return switch (this) {
      BossArchetype.crimsonVanguard => 'boss_vanguard.png',
      BossArchetype.voidMaw => 'boss_voidmaw.png',
      BossArchetype.covenantHost => 'boss_covenant.png',
    };
  }
}

class BossPattern {
  const BossPattern({
    required this.id,
    required this.unlockLevel,
    required this.archetypes,
    required this.execute,
  });

  final String id;
  final int unlockLevel;
  final Set<BossArchetype> archetypes;
  final void Function(BossContext context) execute;
}

class Boss extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame> {
  Boss({required super.position, required this.onDeath})
    : super(
        radius: 42,
        anchor: Anchor.center,
        // Sprite is rendered much larger than this hitbox (see _spriteSize),
        // so keep an explicit low priority within the room so the player
        // and projectiles (default priority) always draw on top of it.
        priority: -1,
        paint: Paint()..color = const Color(0xFF6F5661),
      );

  static const int baseHp = 240;
  static const int contactDamage = 18;

  // Visual size only (the body/hitbox radius above stays 42 for collision
  // and the room-bounds math elsewhere that reads `radius`). Decorative
  // edges of each sprite (runes, fragments, tendril tips) intentionally
  // extend past the hitbox.
  static const double crimsonVanguardSpriteSize = 220;
  static const double voidMawSpriteSize = 240;
  static const double covenantHostSpriteSize = 230;

  final void Function() onDeath;

  late int hp;
  late int maxHp;
  double _contactCooldownLeft = 0;
  double _shotCooldownLeft = 1.4;
  double _dashCooldownLeft = 2.4;
  double _artilleryCooldownLeft = 2.2;
  double _summonCooldownLeft = 4.0;
  double _hexCooldownLeft = 3.2;
  double _specialPatternCooldownLeft = 2.8;
  double _dashTimeLeft = 0;
  double _ricochetWindupLeft = 0;
  double _ricochetTimeLeft = 0;
  double _spiralTimeLeft = 0;
  double _spiralShotCooldownLeft = 0;
  double _phaseTransitionLeft = 0;
  double _reflectLeft = 0;
  double _reflectCooldownLeft = 3.8;
  Color _baseColor = const Color(0xFF6F5661);
  double _flashLeft = 0;
  int _phase = 1;
  int _specialPatternIndex = 0;
  int _ricochetBouncesLeft = 0;
  double _spiralAngle = 0;
  Vector2 _dashDirection = Vector2.zero();
  Vector2 _ricochetVelocity = Vector2.zero();
  Vector2 _knockbackVelocity = Vector2.zero();
  late BossArchetype _archetype;
  Sprite? _sprite;

  double get _spriteSize => switch (_archetype) {
    BossArchetype.crimsonVanguard => crimsonVanguardSpriteSize,
    BossArchetype.voidMaw => voidMawSpriteSize,
    BossArchetype.covenantHost => covenantHostSpriteSize,
  };

  static const List<BossPattern> allPatterns = [
    BossPattern(
      id: 'ricochet_charge',
      unlockLevel: 4,
      archetypes: {BossArchetype.crimsonVanguard},
      execute: _executeRicochetCharge,
    ),
    BossPattern(
      id: 'spiral_barrage',
      unlockLevel: 7,
      archetypes: {BossArchetype.crimsonVanguard, BossArchetype.covenantHost},
      execute: _executeSpiralBarrage,
    ),
    BossPattern(
      id: 'singularity',
      unlockLevel: 10,
      archetypes: {BossArchetype.voidMaw},
      execute: _executeSingularity,
    ),
  ];

  List<BossPattern> availablePatterns(int level) {
    return allPatterns
        .where(
          (pattern) =>
              pattern.unlockLevel <= level &&
              pattern.archetypes.contains(_archetype),
        )
        .toList(growable: false);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _archetype = _selectArchetype(game.gameState.floor);
    _baseColor = _archetype.color;
    paint.color = _baseColor;
    _sprite = await _loadSpriteSafely(_archetype.spriteAsset);
    maxHp =
        (baseHp *
                Balance.enemyHealthScale(
                  floor: game.gameState.floor,
                  room: game.gameState.room,
                ) *
                game.gameState.stats.enemyHealthMultiplier)
            .round();
    hp = maxHp;
    add(CircleHitbox());
  }

  Future<Sprite?> _loadSpriteSafely(String path) async {
    try {
      return await game.loadSprite(path);
    } on Object catch (error) {
      debugPrint('Boss sprite load failed ($path): $error');
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

    final size = _spriteSize;
    final fadePaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    sprite.render(
      canvas,
      position: Vector2.all(radius - size / 2),
      size: Vector2.all(size),
      overridePaint: fadePaint,
    );
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
    if (!_knockbackVelocity.isZero()) {
      position += _knockbackVelocity * dt;
      _knockbackVelocity.scale(0.84);
      if (_knockbackVelocity.length2 < 16) {
        _knockbackVelocity.setZero();
      }
    }

    _updatePhase();
    if (_phaseTransitionLeft > 0) {
      _phaseTransitionLeft -= dt;
      if (_phaseTransitionLeft <= 0) {
        opacity = 1;
      }
      return;
    }

    _contactCooldownLeft -= dt;
    _shotCooldownLeft -= dt;
    _dashCooldownLeft -= dt;
    _artilleryCooldownLeft -= dt;
    _summonCooldownLeft -= dt;
    _hexCooldownLeft -= dt;
    _reflectCooldownLeft -= dt;
    _specialPatternCooldownLeft -= dt;
    if (_reflectLeft > 0) {
      _reflectLeft -= dt;
      paint.color = const Color(0xFFFFD166);
      if (_reflectLeft <= 0) {
        paint.color = _baseColor;
      }
    }

    final toPlayer = game.player.position - position;
    final direction = toPlayer.isZero()
        ? Vector2.zero()
        : toPlayer.normalized();

    _updateSpiralBarrage(dt);
    if (_updateRicochetCharge(dt, direction)) {
      return;
    }

    if (_dashTimeLeft > 0) {
      position += _dashDirection * (340 + _phase * 45) * dt;
      _dashTimeLeft -= dt;
    } else if (!direction.isZero()) {
      position += direction * (64 + _phase * 12) * dt;
    }

    if (_shotCooldownLeft <= 0) {
      _fireSpread(direction);
      _shotCooldownLeft = _attackInterval();
    }

    if (_usesArtillery && _phase >= 2 && _artilleryCooldownLeft <= 0) {
      _callArtillery();
      _artilleryCooldownLeft = _artilleryInterval();
    }

    if (_usesSummons && _phase >= 2 && _summonCooldownLeft <= 0) {
      _summonAdds();
      _summonCooldownLeft = _summonInterval();
    }

    if (_usesHexField && _phase >= 2 && _hexCooldownLeft <= 0) {
      _castHexField();
      _hexCooldownLeft = _hexInterval();
    }

    if (_usesReflect && _phase >= 3 && _reflectCooldownLeft <= 0) {
      _reflectLeft = _reflectDuration();
      _reflectCooldownLeft = _reflectInterval();
    }

    if (_specialPatternCooldownLeft <= 0) {
      _executeNextSpecialPattern();
    }

    if (_usesDash && _dashCooldownLeft <= 0 && !direction.isZero()) {
      _dashDirection = direction;
      _dashTimeLeft = 0.28;
      _dashCooldownLeft = _dashInterval();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other == game.player && _contactCooldownLeft <= 0) {
      game.player.takeDamage(contactDamage, source: position.clone());
      _contactCooldownLeft = 0.8;
    }
  }

  void takeDamage(int amount, {Vector2? source}) {
    if (_phaseTransitionLeft > 0) {
      return;
    }

    if (_reflectLeft > 0) {
      _reflectIncomingShot(amount);
      amount = (amount * 0.65).ceil();
    }
    hp -= amount;
    final killed = hp <= 0;
    game.audio.playHit();
    game.juice.bossHit(this, damage: amount, killed: killed, source: source);
    if (source != null) {
      _applyKnockback(source, strength: killed ? 90 : 36);
    }
    _flash(const Color(0xFFFFFFFF), duration: 0.08);
    opacity = hp <= maxHp / 2 ? 0.82 : 1;
    if (killed) {
      game.gameState.addEssence(22 + game.gameState.curses.length * 3);
      game.gameState.addKill();
      game.addTrauma(strength: 14, duration: 0.35);
      onDeath();
      removeFromParent();
    }
  }

  double _attackInterval() {
    final cursePressure = game.gameState.curses.length * 0.08;
    final riskPressure =
        game.gameState.curses
            .where((curse) => curse.tags.contains(EffectTag.risk))
            .length *
        0.06;
    final lowHpPressure = game.gameState.maxHp <= 70 ? 0.25 : 0;
    final phasePressure = (_phase - 1) * 0.18;
    return (1.35 - cursePressure - riskPressure - lowHpPressure - phasePressure)
        .clamp(0.42, 1.35);
  }

  BossArchetype _selectArchetype(int floor) {
    return switch ((floor - 1) % 3) {
      0 => BossArchetype.crimsonVanguard,
      1 => BossArchetype.voidMaw,
      _ => BossArchetype.covenantHost,
    };
  }

  bool get _usesDash => _archetype == BossArchetype.crimsonVanguard;

  bool get _usesArtillery =>
      _archetype == BossArchetype.voidMaw ||
      (_archetype == BossArchetype.crimsonVanguard &&
          game.gameState.floor >= 8);

  bool get _usesSummons => _archetype == BossArchetype.covenantHost;

  bool get _usesHexField => _archetype == BossArchetype.voidMaw;

  bool get _usesReflect => _archetype == BossArchetype.covenantHost;

  double _dashInterval() {
    final healthCursePressure =
        game.gameState.curses.any(
          (curse) => curse.tags.contains(EffectTag.health),
        )
        ? 0.45
        : 0;
    return (2.9 - _phase * 0.32 - healthCursePressure).clamp(1.25, 2.8);
  }

  double _artilleryInterval() {
    return (2.8 - _phase * 0.25 - game.gameState.floor * 0.035).clamp(
      1.35,
      2.8,
    );
  }

  double _summonInterval() {
    return (5.2 - game.gameState.floor * 0.08).clamp(2.8, 5.2);
  }

  double _hexInterval() {
    return (4.2 - game.gameState.curses.length * 0.08).clamp(2.4, 4.2);
  }

  double _reflectInterval() {
    return (5.4 - game.gameState.floor * 0.06).clamp(3.0, 5.4);
  }

  double _reflectDuration() {
    return game.gameState.floor >= 10 ? 1.25 : 0.9;
  }

  void _executeNextSpecialPattern() {
    final patterns = availablePatterns(game.gameState.floor);
    if (patterns.isEmpty || _ricochetWindupLeft > 0 || _ricochetTimeLeft > 0) {
      _specialPatternCooldownLeft = 1.2;
      return;
    }

    final pattern = patterns[_specialPatternIndex % patterns.length];
    _specialPatternIndex += 1;
    pattern.execute(BossContext(this));
    _specialPatternCooldownLeft = _specialPatternInterval();
  }

  double _specialPatternInterval() {
    return (4.8 - game.gameState.floor * 0.08 - _phase * 0.25).clamp(2.4, 4.8);
  }

  static void _executeRicochetCharge(BossContext context) {
    context.boss._startRicochetCharge();
  }

  static void _executeSpiralBarrage(BossContext context) {
    context.boss._startSpiralBarrage();
  }

  static void _executeSingularity(BossContext context) {
    context.boss._startSingularity();
  }

  void _startRicochetCharge() {
    final toPlayer = game.player.position - position;
    if (toPlayer.isZero()) {
      return;
    }

    final direction = toPlayer.normalized();
    final speed = (430 + _phase * 50 + game.gameState.floor * 7).toDouble();
    _ricochetVelocity = direction * speed;
    _ricochetWindupLeft = (0.72 - game.gameState.floor * 0.025).clamp(
      0.34,
      0.72,
    );
    _ricochetTimeLeft = 0;
    _ricochetBouncesLeft = game.gameState.floor >= 10 ? 2 : 1;
    parent?.add(_BossRicochetTelegraph(segments: _predictRicochetSegments()));
  }

  bool _updateRicochetCharge(double dt, Vector2 direction) {
    if (_ricochetWindupLeft > 0) {
      _ricochetWindupLeft -= dt;
      opacity = 0.72;
      if (_ricochetWindupLeft <= 0) {
        opacity = 1;
        _ricochetTimeLeft = 0.92;
      }
      return true;
    }
    if (_ricochetTimeLeft <= 0) {
      return false;
    }

    position += _ricochetVelocity * dt;
    _ricochetTimeLeft -= dt;
    final bounced = _bounceInsideRoom();
    if (bounced) {
      _ricochetBouncesLeft -= 1;
      game.addTrauma(strength: 6, duration: 0.08);
      if (_ricochetBouncesLeft < 0) {
        _ricochetTimeLeft = 0;
      }
    }
    if ((game.player.position - position).length <= radius + 26) {
      game.player.takeDamage(contactDamage + 6, source: position.clone());
    }
    if (_ricochetTimeLeft <= 0 && !direction.isZero()) {
      _dashDirection = direction;
    }
    return true;
  }

  bool _bounceInsideRoom() {
    final roomSize =
        game.roomManager.currentRoom?.scaledRoomSize ?? Room.roomSize;
    final halfWidth = roomSize.x / 2;
    final halfHeight = roomSize.y / 2;
    final inset = 54 + radius;
    var bounced = false;
    if (position.x < -halfWidth + inset || position.x > halfWidth - inset) {
      _ricochetVelocity.x *= -1;
      position.x = position.x.clamp(-halfWidth + inset, halfWidth - inset);
      bounced = true;
    }
    if (position.y < -halfHeight + inset || position.y > halfHeight - inset) {
      _ricochetVelocity.y *= -1;
      position.y = position.y.clamp(-halfHeight + inset, halfHeight - inset);
      bounced = true;
    }
    return bounced;
  }

  List<({Vector2 start, Vector2 end})> _predictRicochetSegments() {
    final roomSize =
        game.roomManager.currentRoom?.scaledRoomSize ?? Room.roomSize;
    final halfWidth = roomSize.x / 2;
    final halfHeight = roomSize.y / 2;
    final inset = 54 + radius;
    final segments = <({Vector2 start, Vector2 end})>[];
    var start = position.clone();
    var direction = _ricochetVelocity.normalized();
    final segmentLength = (260 + game.gameState.floor * 18).clamp(260, 480);
    final bounces = game.gameState.floor >= 10 ? 2 : 1;
    for (var i = 0; i <= bounces; i += 1) {
      var end = start + direction * segmentLength.toDouble();
      var reflected = false;
      if (end.x < -halfWidth + inset || end.x > halfWidth - inset) {
        end.x = end.x.clamp(-halfWidth + inset, halfWidth - inset);
        direction.x *= -1;
        reflected = true;
      }
      if (end.y < -halfHeight + inset || end.y > halfHeight - inset) {
        end.y = end.y.clamp(-halfHeight + inset, halfHeight - inset);
        direction.y *= -1;
        reflected = true;
      }
      segments.add((start: start.clone(), end: end.clone()));
      start = end;
      if (!reflected) {
        break;
      }
    }
    return segments;
  }

  void _startSpiralBarrage() {
    _spiralTimeLeft = (1.4 + _phase * 0.22).clamp(1.4, 2.2);
    _spiralShotCooldownLeft = 0;
    _spiralAngle = math.atan2(
      game.player.position.y - position.y,
      game.player.position.x - position.x,
    );
    parent?.add(_BossPulseTelegraph(position: position.clone(), radius: 155));
  }

  void _updateSpiralBarrage(double dt) {
    if (_spiralTimeLeft <= 0) {
      return;
    }

    _spiralTimeLeft -= dt;
    _spiralShotCooldownLeft -= dt;
    _spiralAngle += dt * (2.6 + _phase * 0.35);
    if (_spiralShotCooldownLeft > 0) {
      return;
    }

    final arms = game.gameState.floor >= 12 ? 4 : 3;
    for (var i = 0; i < arms; i += 1) {
      final angle = _spiralAngle + math.pi * 2 * i / arms;
      parent?.add(
        BossProjectile(
          position: position.clone(),
          direction: Vector2(math.cos(angle), math.sin(angle)),
          damage: 10 + _phase,
        ),
      );
    }
    _spiralShotCooldownLeft = (0.22 - game.gameState.floor * 0.006).clamp(
      0.12,
      0.22,
    );
  }

  void _startSingularity() {
    final center = _clampedRoomPoint(game.player.position.clone());
    parent?.add(
      _BossSingularity(
        position: center,
        radius: (136 + game.gameState.floor * 5).clamp(136, 220).toDouble(),
        damage: 14 + _phase * 2,
        pullStrength: (96 + game.gameState.floor * 6).clamp(96, 180).toDouble(),
      ),
    );
  }

  void _fireSpread(Vector2 direction) {
    if (direction.isZero()) {
      return;
    }

    final riskCount = game.gameState.curses
        .where((curse) => curse.tags.contains(EffectTag.risk))
        .length;
    final angles = switch (_phase) {
      1 => [-0.28, 0.0, 0.28],
      2 => [-0.46, -0.22, 0.0, 0.22, 0.46],
      _ =>
        riskCount >= 3
            ? [-0.66, -0.44, -0.22, 0.0, 0.22, 0.44, 0.66]
            : [-0.56, -0.28, 0.0, 0.28, 0.56],
    };
    for (final angle in angles) {
      final shotDirection = direction.clone()..rotate(angle);
      parent?.add(
        BossProjectile(position: position.clone(), direction: shotDirection),
      );
    }
  }

  void _callArtillery() {
    final count = switch (_phase) {
      1 => 0,
      2 => game.gameState.floor >= 8 ? 3 : 2,
      _ => game.gameState.floor >= 12 ? 5 : 4,
    };
    final radius = (74 + game.gameState.floor * 3).clamp(74, 118).toDouble();
    final playerPosition = game.player.position.clone();
    final targets = <Vector2>[playerPosition];
    for (var i = 1; i < count; i += 1) {
      final angle = math.pi * 2 * i / count + _phase * 0.35;
      targets.add(
        _clampedRoomPoint(
          playerPosition + Vector2(math.cos(angle), math.sin(angle)) * 96,
        ),
      );
    }

    parent?.add(
      _BossArtilleryTelegraph(
        targets: targets.map(_clampedRoomPoint).toList(),
        radius: radius,
        damage: 12 + _phase * 2,
      ),
    );
  }

  void _summonAdds() {
    final count = game.gameState.floor >= 12 ? 2 : 1;
    for (var i = 0; i < count; i += 1) {
      final angle = math.pi * 2 * i / count + _phase;
      final spawnPosition = _clampedRoomPoint(
        position + Vector2(math.cos(angle), math.sin(angle)) * 92,
      );
      parent?.add(
        Enemy(
          position: spawnPosition,
          kind: game.gameState.floor >= 10
              ? EnemyKind.hexer
              : EnemyKind.charger,
          healthMultiplier: 0.75,
          damage: 8 + _phase,
          radius: 15,
          color: const Color(0xFF8E445A),
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
  }

  void _castHexField() {
    final radius = (98 + game.gameState.curses.length * 4).clamp(98, 150);
    parent?.add(
      _BossHexField(
        position: game.player.position.clone(),
        radius: radius.toDouble(),
        damage: 8 + _phase,
      ),
    );
  }

  void _reflectIncomingShot(int amount) {
    final toPlayer = game.player.position - position;
    if (toPlayer.isZero()) {
      return;
    }

    final count = game.gameState.floor >= 13 ? 5 : 3;
    final spread = count >= 5 ? 0.82 : 0.48;
    final startAngle = -spread / 2;
    final step = spread / (count - 1);
    final baseDirection = toPlayer.normalized();
    final damage = (amount * 0.24).ceil().clamp(5, 18);
    for (var i = 0; i < count; i += 1) {
      final shotDirection = baseDirection.clone()
        ..rotate(startAngle + step * i);
      parent?.add(
        BossProjectile(
          position: position.clone(),
          direction: shotDirection,
          damage: damage,
          color: const Color(0xFFFFD166),
        ),
      );
    }
  }

  Vector2 _clampedRoomPoint(Vector2 point) {
    final roomSize =
        game.roomManager.currentRoom?.scaledRoomSize ?? Room.roomSize;
    final halfWidth = roomSize.x / 2;
    final halfHeight = roomSize.y / 2;
    const inset = 54.0;
    return Vector2(
      point.x.clamp(-halfWidth + inset, halfWidth - inset).toDouble(),
      point.y.clamp(-halfHeight + inset, halfHeight - inset).toDouble(),
    );
  }

  void _updatePhase() {
    final hpRatio = hp / maxHp;
    final nextPhase = hpRatio <= 0.33
        ? 3
        : hpRatio <= 0.66
        ? 2
        : 1;

    if (nextPhase <= _phase) {
      return;
    }

    _phase = nextPhase;
    _phaseTransitionLeft = 0.7;
    opacity = 0.55;
    paint.color = _phaseColor(_phase);
    _baseColor = paint.color;
    game.juice.phaseTransition(position);
  }

  Color _phaseColor(int phase) {
    if (phase <= 1) {
      return _archetype.color;
    }
    final boost = phase == 2 ? 28 : 54;
    int channel(double base, double extra) {
      return (base * 255 + extra).round().clamp(0, 255).toInt();
    }

    return Color.fromARGB(
      255,
      channel(_archetype.color.r, boost.toDouble()),
      channel(_archetype.color.g, boost * 0.45),
      channel(_archetype.color.b, boost * 0.55),
    );
  }

  void _flash(Color color, {required double duration}) {
    paint.color = color;
    _flashLeft = duration;
  }

  void _applyKnockback(Vector2 source, {required double strength}) {
    final direction = position - source;
    if (direction.isZero()) {
      return;
    }

    _knockbackVelocity += direction.normalized() * strength;
    if (_knockbackVelocity.length > 115) {
      _knockbackVelocity = _knockbackVelocity.normalized() * 115;
    }
  }
}

class BossProjectile extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame>, OffscreenThreat {
  BossProjectile({
    required super.position,
    required Vector2 direction,
    this.damage = 12,
    Color color = const Color(0xFFB11238),
  }) : _direction = direction.normalized(),
       super(radius: 7, anchor: Anchor.center, paint: Paint()..color = color);

  final Vector2 _direction;
  final int damage;
  double _lifeLeft = 2.2;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += _direction * 250 * dt;
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
}

class _BossRicochetTelegraph extends PositionComponent with OffscreenThreat {
  _BossRicochetTelegraph({required this.segments}) : super(priority: -2);

  final List<({Vector2 start, Vector2 end})> segments;
  double _lifeLeft = 0.72;

  @override
  double get threatUrgency => 0.9;

  @override
  List<Vector2> get threatPositions => [
    for (final segment in segments) segment.end,
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (1 - _lifeLeft / 0.72).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(
        0xFFFF5A76,
      ).withValues(alpha: 0.42 + progress * 0.38)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final outline = Paint()
      ..color = const Color(0xFFD7B84F).withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final segment in segments) {
      final start = Offset(segment.start.x, segment.start.y);
      final end = Offset(segment.end.x, segment.end.y);
      canvas
        ..drawLine(start, end, paint)
        ..drawLine(start, end, outline);
    }
  }
}

class _BossPulseTelegraph extends CircleComponent with OffscreenThreat {
  _BossPulseTelegraph({required super.position, required double radius})
    : super(
        radius: radius,
        anchor: Anchor.center,
        priority: -3,
        paint: Paint()..color = const Color(0xFFB11238).withValues(alpha: 0.18),
      );

  double _lifeLeft = 0.55;

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    opacity = (_lifeLeft / 0.55).clamp(0.0, 1.0);
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final outline = Paint()
      ..color = const Color(0xFFFF5A76).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(radius, radius), radius, outline);
  }
}

class _BossArtilleryTelegraph extends PositionComponent
    with HasGameReference<CurseboundGame>, OffscreenThreat {
  _BossArtilleryTelegraph({
    required this.targets,
    required this.radius,
    required this.damage,
  }) : super(priority: -3);

  final List<Vector2> targets;
  final double radius;
  final int damage;
  double _timeLeft = 0.72;

  @override
  double get threatUrgency =>
      0.82 + (1 - _timeLeft / 0.72).clamp(0.0, 1.0) * 0.1;

  @override
  List<Vector2> get threatPositions => targets;

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      for (final target in targets) {
        game.juice.explosion(target);
        if ((game.player.position - target).length <= radius) {
          game.player.takeDamage(damage, source: target.clone());
        }
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (1 - _timeLeft / 0.72).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(
        0xFFB11238,
      ).withValues(alpha: 0.24 + progress * 0.34)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFFFF5A76).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final target in targets) {
      canvas
        ..drawCircle(Offset(target.x, target.y), radius, paint)
        ..drawCircle(Offset(target.x, target.y), radius, outline);
    }
  }
}

class _BossSingularity extends CircleComponent
    with HasGameReference<CurseboundGame>, OffscreenThreat {
  _BossSingularity({
    required super.position,
    required double radius,
    required this.damage,
    required this.pullStrength,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         priority: -5,
         paint: Paint()
           ..color = const Color(0xFF1A1028).withValues(alpha: 0.34),
       );

  final int damage;
  final double pullStrength;
  double _lifeLeft = 3.0;
  double _damageCooldownLeft = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    _damageCooldownLeft -= dt;

    final toCenter = position - game.player.position;
    final distance = toCenter.length;
    if (distance > 0 && distance <= radius) {
      final pullRatio = (1 - distance / radius).clamp(0.18, 1.0);
      game.player.position +=
          toCenter.normalized() * pullStrength * pullRatio * dt;
      if (distance <= 28 && _damageCooldownLeft <= 0) {
        game.player.takeDamage(damage, source: position.clone());
        _damageCooldownLeft = 0.55;
      }
    }

    opacity = (_lifeLeft / 3.0).clamp(0.0, 1.0);
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF7B2CBF).withValues(alpha: 0.8);
    final core = Paint()
      ..color = const Color(0xFFB11238).withValues(alpha: 0.58);
    canvas
      ..drawCircle(Offset(radius, radius), radius, outer)
      ..drawCircle(Offset(radius, radius), 28, core);
  }
}

class _BossHexField extends CircleComponent
    with CollisionCallbacks, HasGameReference<CurseboundGame>, OffscreenThreat {
  _BossHexField({
    required super.position,
    required double radius,
    required this.damage,
  }) : super(
         radius: radius,
         anchor: Anchor.center,
         priority: -4,
         paint: Paint()..color = const Color(0xFF7B2CBF).withValues(alpha: 0.2),
       );

  final int damage;
  double _lifeLeft = 2.4;
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
    opacity = (_lifeLeft / 2.4).clamp(0.0, 1.0);
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other == game.player && _damageCooldownLeft <= 0) {
      game.player.takeDamage(damage, source: position.clone());
      game.player.applySlow(multiplier: 0.68, duration: 1.1);
      _damageCooldownLeft = 0.5;
    }
  }
}
