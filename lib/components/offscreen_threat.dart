import 'package:flame/components.dart';

mixin OffscreenThreat on PositionComponent {
  double get threatUrgency => 0.8;

  List<Vector2> get threatPositions => [position];
}
