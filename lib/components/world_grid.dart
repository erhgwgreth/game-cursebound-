import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WorldGrid extends PositionComponent {
  WorldGrid()
    : _gridPaint = Paint()
        ..color = const Color(0xFF1A1D26)
        ..strokeWidth = 1,
      _axisPaint = Paint()
        ..color = const Color(0xFF3D4354)
        ..strokeWidth = 2,
      super(
        position: Vector2(-4000, -4000),
        size: Vector2.all(8000),
        priority: -100,
      );

  static const double cellSize = 80;

  final Paint _gridPaint;
  final Paint _axisPaint;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (double x = 0; x <= size.x; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);
    }

    for (double y = 0; y <= size.y; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);
    }

    final origin = -position;
    canvas.drawLine(Offset(origin.x, 0), Offset(origin.x, size.y), _axisPaint);
    canvas.drawLine(Offset(0, origin.y), Offset(size.x, origin.y), _axisPaint);
  }
}
