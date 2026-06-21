import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

class EffectSpriteCache {
  EffectSpriteCache._();

  static final Map<String, Sprite?> _cache = {};

  static Future<Sprite?> load(FlameGame game, String fileName) async {
    if (_cache.containsKey(fileName)) {
      return _cache[fileName];
    }

    try {
      final sprite = await game.loadSprite(fileName);
      _cache[fileName] = sprite;
      return sprite;
    } on Object catch (error) {
      debugPrint('Effect sprite load failed ($fileName): $error');
      _cache[fileName] = null;
      return null;
    }
  }
}
