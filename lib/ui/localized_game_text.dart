import '../data/blessing.dart';
import '../data/boss_boon.dart';
import '../data/curse.dart';
import '../data/game_modifier.dart';
import '../data/relic.dart';
import '../data/room_type.dart';
import '../systems/localization_service.dart';
import '../systems/synergy_resolver.dart';

String localizedModifierName(GameModifier modifier) {
  final key = '${_modifierPrefix(modifier)}.${modifier.id}.name';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? modifier.name : translated;
}

String localizedModifierDescription(GameModifier modifier) {
  final key = '${_modifierPrefix(modifier)}.${modifier.id}.desc';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? modifier.description : translated;
}

String localizedTag(EffectTag tag) {
  final key = 'tag.${tag.name}';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? tag.name : translated;
}

String localizedStackName(GameModifier modifier, int level) {
  final name = localizedModifierName(modifier);
  return level <= 1 ? name : '$name Lv.$level';
}

String localizedSynergyName(BuildSynergy synergy) {
  final key = 'synergy.${synergy.id}.name';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? synergy.name : translated;
}

String localizedSynergyDescription(BuildSynergy synergy) {
  final key = 'synergy.${synergy.id}.desc';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? synergy.description : translated;
}

String localizedConflictName(BuildConflict conflict) {
  final key = 'conflict.${conflict.id}.name';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? conflict.name : translated;
}

String localizedConflictDescription(BuildConflict conflict) {
  final key = 'conflict.${conflict.id}.desc';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? conflict.description : translated;
}

String localizedRoomType(RoomType type) {
  final key = 'room.${type.name}';
  final translated = LocalizationService.instance.tr(key);
  return translated == key ? type.label : translated;
}

String _modifierPrefix(GameModifier modifier) {
  return switch (modifier) {
    Blessing() => 'blessing',
    Curse() => 'curse',
    Relic() => 'relic',
    BossBoon() => 'boon',
    _ => 'modifier',
  };
}
