import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

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

class HitSpark extends CircleComponent {
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
