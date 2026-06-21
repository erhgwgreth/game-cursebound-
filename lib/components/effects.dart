import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../game/cursebound_game.dart';
import '../systems/effect_sprite_cache.dart';
import '../ui/app_text.dart';

class BurstParticle extends CircleComponent {
  BurstParticle({
    required super.position,
    required this.velocity,
    required Color color,
    this.life = 0.34,
    double radius = 4,
  }) : _startLife = life,
       super(
         radius: radius,
         anchor: Anchor.center,
         priority: 180,
         paint: Paint()..color = color,
       );

  final Vector2 velocity;
  final double _startLife;
  double life;

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;
    position += velocity * dt;
    velocity.scale(0.88);

    final progress = (1 - life / _startLife).clamp(0, 1).toDouble();
    scale.setAll(1 + progress * 0.55);
    paint.color = paint.color.withValues(alpha: (1 - progress) * 0.9);

    if (life <= 0) {
      removeFromParent();
    }
  }
}

class Afterimage extends RectangleComponent {
  Afterimage({
    required super.position,
    required super.size,
    required Color color,
  }) : super(
         anchor: Anchor.center,
         priority: 20,
         paint: Paint()..color = color.withValues(alpha: 0.34),
       );

  double _lifeLeft = 0.18;

  @override
  void update(double dt) {
    super.update(dt);

    _lifeLeft -= dt;
    final progress = (1 - _lifeLeft / 0.18).clamp(0, 1).toDouble();
    scale.setAll(1 + progress * 0.18);
    paint.color = paint.color.withValues(alpha: (1 - progress) * 0.34);

    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }
}

class HitSpark extends CircleComponent with HasGameReference<CurseboundGame> {
  HitSpark({
    required super.position,
    Color color = const Color(0xFFD7B84F),
    double radius = 8,
  }) : _startRadius = radius,
       super(
         radius: radius,
         anchor: Anchor.center,
         paint: Paint()..color = color,
       );

  final double _startRadius;
  double _lifeLeft = 0.18;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await EffectSpriteCache.load(game, 'hit_spark.png');
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifeLeft -= dt;
    final progress = (1 - _lifeLeft / 0.18).clamp(0, 1).toDouble();
    radius = _startRadius + progress * 20;
    paint.color = paint.color.withValues(alpha: (1 - progress) * 0.85);

    if (_lifeLeft <= 0) {
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

    final progress = (1 - _lifeLeft / 0.18).clamp(0, 1).toDouble();
    final drawSize = (_startRadius * 4.5) + progress * 34;
    final alpha = (1 - progress) * 0.9;
    sprite.render(
      canvas,
      position: Vector2.all(radius - drawSize / 2),
      size: Vector2.all(drawSize),
      overridePaint: Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha),
    );
  }
}

class OneShotSpriteEffect extends PositionComponent
    with HasGameReference<CurseboundGame> {
  OneShotSpriteEffect({
    required super.position,
    required this.assetName,
    required this.startSize,
    required this.endSize,
    this.life = 0.26,
    this.startOpacity = 0.95,
    this.endOpacity = 0,
    this.effectAngle = 0,
    int priority = 170,
  }) : _lifeLeft = life,
       super(anchor: Anchor.center, priority: priority, angle: effectAngle);

  final String assetName;
  final double startSize;
  final double endSize;
  final double life;
  final double startOpacity;
  final double endOpacity;
  final double effectAngle;
  double _lifeLeft;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await EffectSpriteCache.load(game, assetName);
  }

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
    final sprite = _sprite;
    if (sprite == null) {
      return;
    }

    final progress = (1 - _lifeLeft / life).clamp(0, 1).toDouble();
    final drawSize = startSize + (endSize - startSize) * progress;
    final alpha = startOpacity + (endOpacity - startOpacity) * progress;
    sprite.render(
      canvas,
      position: Vector2.all(-drawSize / 2),
      size: Vector2.all(drawSize),
      overridePaint: Paint()
        ..color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 1)),
    );
  }
}

class ExplosionAnimationEffect extends PositionComponent
    with HasGameReference<CurseboundGame> {
  ExplosionAnimationEffect({required super.position})
    : _visualScale = 0.9 + _random.nextDouble() * 0.2,
      _visualAngle = _random.nextDouble() * math.pi * 2,
      super(anchor: Anchor.center, priority: 170);

  static final math.Random _random = math.Random();
  static const List<String> _frameAssetNames = [
    'explosion_anim_0.png',
    'explosion_anim_1.png',
    'explosion_anim_2.png',
    'explosion_anim_3.png',
  ];
  static const double _stepTime = 0.07;
  static const double _life = _stepTime * 4;
  static const double _startSize = 78;
  static const double _endSize = 128;

  final double _visualScale;
  final double _visualAngle;
  double _lifeLeft = _life;
  SpriteAnimationComponent? _animationComponent;
  Sprite? _fallbackSprite;
  bool _usesFallback = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final frames = <Sprite>[];
    for (final assetName in _frameAssetNames) {
      final sprite = await EffectSpriteCache.load(game, assetName);
      if (sprite == null) {
        frames.clear();
        break;
      }
      frames.add(sprite);
    }

    if (frames.length == _frameAssetNames.length) {
      final animation = SpriteAnimation.spriteList(
        frames,
        stepTime: _stepTime,
        loop: false,
      );
      _animationComponent = SpriteAnimationComponent(
        animation: animation,
        anchor: Anchor.center,
        size: Vector2.all(_startSize * _visualScale),
        angle: _visualAngle,
        removeOnFinish: true,
      );
      add(_animationComponent!);
      return;
    }

    _usesFallback = true;
    _fallbackSprite = await EffectSpriteCache.load(game, 'explosion.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;

    final progress = (1 - _lifeLeft / _life).clamp(0, 1).toDouble();
    final drawSize =
        (_startSize + (_endSize - _startSize) * progress) * _visualScale;
    _animationComponent?.size = Vector2.all(drawSize);

    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_usesFallback) {
      super.render(canvas);
      return;
    }

    final progress = (1 - _lifeLeft / _life).clamp(0, 1).toDouble();
    final drawSize =
        (_startSize + (_endSize - _startSize) * progress) * _visualScale;
    final alpha = (1 - progress).clamp(0, 1).toDouble();
    final sprite = _fallbackSprite;
    if (sprite != null) {
      canvas
        ..save()
        ..rotate(_visualAngle);
      sprite.render(
        canvas,
        position: Vector2.all(-drawSize / 2),
        size: Vector2.all(drawSize),
        overridePaint: Paint()
          ..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      canvas.restore();
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFFFF5A76).withValues(alpha: alpha * 0.75);
    canvas.drawCircle(Offset.zero, drawSize / 2, paint);
  }
}

class FloatingText extends PositionComponent {
  FloatingText({
    required super.position,
    required this.text,
    required this.color,
    this.textScale = 1,
  }) : super(anchor: Anchor.center, priority: 200);

  final String text;
  final Color color;
  final double textScale;
  double _lifeLeft = 0.58;

  @override
  void update(double dt) {
    super.update(dt);
    _lifeLeft -= dt;
    position.y -= 34 * dt;
    if (_lifeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (1 - _lifeLeft / 0.58).clamp(0, 1).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppText.fontFamily,
          color: color.withValues(alpha: 1 - progress),
          fontSize: 18 * textScale,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
}
