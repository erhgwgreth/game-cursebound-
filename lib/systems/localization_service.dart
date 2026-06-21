import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum AppLocale { en, ko }

class LocalizationService extends ChangeNotifier {
  LocalizationService._();

  static final LocalizationService instance = LocalizationService._();

  AppLocale _locale = AppLocale.en;

  AppLocale get locale => _locale;

  bool get isKorean => _locale == AppLocale.ko;

  File get _saveFile => File('cursebound_settings.json');

  Future<void> load() async {
    try {
      if (await _saveFile.exists()) {
        final json = jsonDecode(await _saveFile.readAsString());
        if (json is Map<String, Object?>) {
          final localeName = json['locale'];
          _locale = AppLocale.values.firstWhere(
            (locale) => locale.name == localeName,
            orElse: () => AppLocale.en,
          );
        }
      }
    } on Object catch (error) {
      debugPrint('Localization load failed: $error');
    } finally {
      notifyListeners();
    }
  }

  String tr(String key, {Map<String, String>? params}) {
    final localized = _strings[_locale]?[key];
    final fallback = _strings[AppLocale.en]?[key];
    return _interpolate(localized ?? fallback ?? key, params);
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    notifyListeners();
    await _persist();
  }

  String _interpolate(String value, Map<String, String>? params) {
    var result = value;
    for (final entry in params?.entries ?? const Iterable.empty()) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  Future<void> _persist() async {
    try {
      final payload = const JsonEncoder.withIndent(
        '  ',
      ).convert({'locale': _locale.name});
      await _saveFile.writeAsString(payload);
    } on Object catch (error) {
      debugPrint('Localization save failed: $error');
    }
  }

  static const Map<AppLocale, Map<String, String>> _strings = {
    AppLocale.en: {
      'app.title': 'Abyssbound',
      'app.tagline': 'Every blessing binds a curse.',
      'ui.title.start': 'Start',
      'ui.title.loading': 'Loading...',
      'ui.title.unlock': 'Unlock',
      'ui.title.codex': 'Codex',
      'ui.title.settings': 'Settings',
      'ui.title.quit': 'Quit',
      'ui.meta.sigils': 'Sigils',
      'ui.meta.best_floor': 'Best Floor',
      'ui.meta.runs': 'Runs',
      'ui.settings.language': 'Language',
      'ui.settings.english': 'English',
      'ui.settings.korean': 'Korean',
      'ui.settings.bgm_volume': 'BGM Volume',
      'ui.settings.combat_feedback': 'Combat feedback',
      'ui.settings.screen_shake': 'Screen shake',
      'ui.settings.offscreen_warnings': 'Offscreen warnings',
      'ui.common.close': 'Close',
      'ui.common.owned': 'Owned',
      'ui.common.locked': 'Locked',
      'ui.common.current': 'Current',
      'ui.common.level': 'Level',
      'ui.unlock.title': 'Unlock',
      'ui.unlock.stats': 'Stats',
      'ui.unlock.relics': 'Relics',
      'ui.unlock.boons': 'Boons',
      'ui.unlock.revival': 'Revival',
      'ui.unlock.stat_title': 'Stat Upgrades',
      'ui.unlock.stat_subtitle':
          'Small permanent boosts with strict caps. They help, but they do not solve high floors by themselves.',
      'ui.unlock.relic_title': 'Relic Unlocks',
      'ui.unlock.relic_subtitle':
          'Unlock relics individually, then raise how many relic candidates appear at run start.',
      'ui.unlock.relic_choices': 'Starting Relic Choices',
      'ui.unlock.relic_choices_desc':
          '{current} choices. 0 means runs begin without a relic.',
      'ui.unlock.boon_title': 'Special Boons',
      'ui.unlock.boon_subtitle':
          'High-cost meta power. These alter the start of a run with boss-grade passives.',
      'ui.unlock.boon_active': 'Active: random Boss Boon at run start',
      'ui.unlock.boon_extra':
          'The granted Boon still has tags and works with synergies.',
      'ui.unlock.revival_title': 'Revival',
      'ui.unlock.revival_subtitle':
          'A single safety net, bound by a cost. It prevents one death per run, then gives you another curse.',
      'ui.unlock.revival_active':
          'Active: once per run, half HP + random curse',
      'ui.contract.title': 'Choose a Pact',
      'ui.contract.subtitle':
          'Every blessing binds a curse. Power has a price.',
      'ui.contract.blessing': 'Blessing',
      'ui.contract.curse': 'Curse',
      'ui.contract.bind': 'Bind Pact',
      'ui.contract.preview_synergy': 'Synergy',
      'ui.contract.preview_risk': 'Risk',
      'ui.boon.title': 'Claim a Boss Boon',
      'ui.boon.subtitle':
          'A power taken from a fallen guardian. No curse is bound to this reward.',
      'ui.boon.label': 'Boss Boon',
      'ui.boon.claim': 'Claim Power',
      'ui.relic.title': 'Choose a Starting Relic',
      'ui.relic.subtitle':
          'A relic shapes the run before the first pact is made.',
      'ui.relic.begin': 'Begin with this',
      'ui.memory.title': 'Memory Chamber',
      'ui.memory.subtitle': 'Fragment {order}',
      'ui.memory.subtitle_complete': 'No new memory rises from the dark.',
      'ui.memory.continue': 'Continue',
      'ui.inscription.title': 'Sin Inscription',
      'ui.inscription.prompt': 'Press E to read the inscription',
      'ui.codex.title': 'Codex',
      'ui.codex.subtitle': 'Fragments recovered across all runs.',
      'ui.codex.progress': '{revealed}/{total} revealed',
      'ui.codex.all': 'All',
      'ui.codex.memories': 'Memories',
      'ui.codex.inscriptions': 'Sin Inscriptions',
      'ui.codex.memory_number': 'Memory {order}',
      'ui.codex.locked': '???',
      'ui.codex.locked_desc': 'This fragment has not surfaced yet.',
      'ui.codex.no_inscriptions': 'No inscriptions have been read yet.',
      'ui.hud.essence': 'Essence',
      'ui.hud.floor': 'Floor',
      'ui.hud.room': 'Room',
      'ui.hud.kills': 'Kills',
      'ui.hud.curses': 'Curses',
      'ui.hud.relic': 'Relic',
      'ui.hud.boss_favor':
          'Boss Favor active: essence x{multiplier} until you take stairs',
      'ui.hud.revival_ready': 'Revival ready: half HP + random curse on death',
      'ui.hud.revival_spent': 'Revival spent',
      'ui.hud.controls':
          'Juice {juice}   Shake {shake}   Tab/B Build   Esc Pause',
      'ui.hud.boss_room':
          'Boss room. The boss attacks faster as curses pile up.',
      'ui.hud.room_cleared':
          'Room cleared. Touch the altar for a pact, then use an open door.',
      'ui.result.died': 'You Died',
      'ui.result.abandoned': 'Run Abandoned',
      'ui.result.highest_floor': 'Highest Floor',
      'ui.result.ended_floor': 'Ended On Floor',
      'ui.result.room': 'Room',
      'ui.result.kills': 'Kills',
      'ui.result.curses': 'Curses',
      'ui.result.relic': 'Relic',
      'ui.result.none': 'None',
      'ui.result.curse_bonus': 'Curse Bonus',
      'ui.result.sigils_earned': 'Sigils Earned',
      'ui.result.record': 'Record',
      'ui.result.new_best_score': 'New Best Score',
      'ui.result.depth': 'Depth',
      'ui.result.new_best_floor': 'New Best Floor',
      'ui.result.score': 'Score',
      'ui.result.restart': 'Restart',
      'ui.summary.title': 'Build Summary',
      'ui.pause.title': 'Run Details',
      'ui.section.stats': 'Stats',
      'ui.section.run': 'Run',
      'ui.section.relic': 'Relic',
      'ui.section.boss_boons': 'Boss Boons',
      'ui.section.blessings': 'Blessings',
      'ui.section.curses': 'Curses',
      'ui.section.synergies': 'Synergies',
      'ui.section.conflicts': 'Conflicts',
      'ui.section.settings': 'Settings',
      'ui.section.controls': 'Controls',
      'ui.empty.default': 'Empty.',
      'ui.empty.boss_boons': 'No boss boons yet.',
      'ui.empty.blessings': 'No blessings yet.',
      'ui.empty.curses': 'No curses yet.',
      'ui.empty.synergies': 'No active synergies.',
      'ui.empty.conflicts': 'No active conflicts.',
      'ui.action.resume': 'Resume',
      'ui.action.abandon': 'Abandon Run',
      'ui.stat.max_hp': 'Max HP',
      'ui.stat.move_speed': 'Move Speed',
      'ui.stat.attack_damage': 'Attack Damage',
      'ui.stat.attack_speed': 'Attack Speed',
      'ui.stat.dash_distance': 'Dash Distance',
      'ui.stat.dash_cooldown': 'Dash Cooldown',
      'ui.stat.projectile_speed': 'Projectile Speed',
      'ui.stat.projectile_size': 'Projectile Size',
      'ui.stat.critical': 'Critical',
      'ui.stat.healing': 'Healing',
      'ui.stat.damage_taken': 'Damage Taken',
      'ui.stat.enemy_hp': 'Enemy HP',
      'ui.stat.heal_on_kill': 'Heal On Kill',
      'ui.stat.current_floor': 'Current Floor',
      'ui.stat.highest_floor': 'Highest Floor',
      'ui.stat.room_visits': 'Room Visits',
      'ui.stat.room_type': 'Room Type',
      'ui.stat.elapsed': 'Elapsed',
      'ui.stat.damage': 'Damage',
      'ui.stat.move': 'Move',
      'ui.stat.hp': 'HP',
      'ui.stat.score': 'Score',
      'ui.stat.kills': 'Kills',
      'ui.stat.essence': 'Essence',
      'ui.stat.sigils': 'Sigils',
      'ui.stat.shake': 'Shake',
      'ui.status.dead_phase': 'Dead. Result screen arrives in Phase 6.',
      'ui.help.move': 'WASD / Arrow: move',
      'ui.help.dash': 'Space / Shift: dash',
      'ui.help.shoot': 'Mouse click: shoot',
      'ui.help.build': 'Tab / B: build summary',
      'ui.help.pause': 'Esc: resume / pause',
      'ui.help.build_close': 'Tab/B: close build summary   Esc: pause',
      'synergy.glass_cannon.name': 'Glass Cannon',
      'synergy.glass_cannon.desc': 'Lower HP increases attack damage.',
      'synergy.rush_slayer.name': 'Rush Slayer',
      'synergy.rush_slayer.desc': 'Moving boosts attack damage and speed.',
      'synergy.fire_chain.name': 'Fire Chain',
      'synergy.fire_chain.desc': 'Projectiles leave damaging fire patches.',
      'synergy.reapers_deal.name': "Reaper's Deal",
      'synergy.reapers_deal.desc': 'Kills grant brief invincibility and speed.',
      'conflict.bleeding_debt.name': 'Bleeding Debt',
      'conflict.bleeding_debt.desc':
          'Healing is weak and incoming damage is harsher.',
      'room.start': 'Start',
      'room.normal': 'Normal',
      'room.treasure': 'Treasure',
      'room.miniboss': 'Miniboss',
      'room.elite': 'Elite',
      'room.challenge': 'Challenge',
      'room.merchant': 'Offering',
      'room.offering': 'Offering',
      'room.upstairs': 'Stairs',
      'room.memory': 'Memory',
      'room.boss': 'Boss',
      'ui.offering.title': 'Offering Altar',
      'ui.offering.essence': 'Essence: {amount}',
      'ui.offering.cleanse': 'Cleanse Curse',
      'ui.offering.cleanse_named': 'Cleanse Curse: {name}',
      'ui.offering.no_curse': 'No curse to remove.',
      'ui.offering.cleanse_cost':
          'Offer {cost} Essence. Synergies and conflicts recalculate.',
      'ui.offering.deeper': 'Deeper Offering',
      'ui.offering.deeper_spent': 'Deeper Offering: Spent',
      'ui.offering.deeper_spent_desc':
          'The altar has already accepted this blood.',
      'ui.offering.deeper_desc': 'Gain {blessing}, but take {curse}. Free.',
      'ui.offering.blessing': 'Offering Blessing: {name}',
      'ui.offering.blessing_claimed': 'Offering Blessing: Claimed',
      'ui.offering.blessing_claimed_desc':
          'This blessing has already been drawn from the altar.',
      'ui.offering.blessing_desc': '{description} ({price} Essence)',
      'ui.offering.reroll': 'Scatter Ashes',
      'ui.offering.reroll_desc':
          'Offer {cost} Essence to redraw offerings and whispers.',
      'ui.offering.step_away': 'Step Away',
      'story.memory.01':
          'The day they dressed you for the altar, everyone called it an honor. Only your hands knew it was a funeral.',
      'story.memory.02':
          'Your companions did not meet your eyes. Their purses were heavy. Their prayers were louder than your name.',
      'story.memory.03':
          'The cult called you chosen because it sounded kinder than sold.',
      'story.memory.04':
          'At the bottom of the pit, something smiled without a face. It offered a way upward, one curse at a time.',
      'story.memory.05':
          'With each floor, your blood learned new shapes. The monster you feared began answering to your voice.',
      'story.memory.06':
          'You climb toward a surface that never answers. Perhaps the altar was not below you. Perhaps it was always ahead.',
      'story.memory.complete':
          'The chamber is quiet. Every memory it can return has already been taken.',
      'story.memory.already_claimed':
          'Only an echo remains here. This memory has already been reclaimed.',
      'story.sin.abandonment.01':
          'Those cast away learn the shape of every door that closed behind them.',
      'story.sin.abandonment.02':
          'A name forgotten by friends echoes louder than any prayer.',
      'story.sin.greed.01':
          'Gold does not buy mercy. It only teaches betrayal to smile.',
      'story.sin.greed.02':
          'Their hands shook when they counted the coins. Not from guilt. From hunger.',
      'story.sin.betrayal.01':
          'The deepest wound is made by someone who knew where you trusted them.',
      'story.sin.betrayal.02':
          'An oath broken in silence still reaches the altar.',
      'story.sin.fanaticism.01':
          'Faith sharpens knives and calls the blood proof.',
      'story.sin.fanaticism.02':
          'They praised the sacrifice so no one had to hear the scream.',
      'story.sin.pride.01':
          'The proud build stairways and mistake height for absolution.',
      'story.sin.pride.02': 'To climb forever is also a kind of kneeling.',
      'tag.movement': 'movement',
      'tag.health': 'health',
      'tag.projectile': 'projectile',
      'tag.melee': 'melee',
      'tag.fire': 'fire',
      'tag.onKill': 'on kill',
      'tag.onHit': 'on hit',
      'tag.lowHp': 'low HP',
      'tag.risk': 'risk',
      'blessing.quick_hands.name': 'Quick Hands',
      'blessing.quick_hands.desc': 'Attack speed +30%',
      'blessing.sharpened_will.name': 'Sharpened Will',
      'blessing.sharpened_will.desc': 'Attack damage +25%',
      'blessing.long_step.name': 'Long Step',
      'blessing.long_step.desc': 'Dash distance +30%',
      'blessing.fleet_body.name': 'Fleet Body',
      'blessing.fleet_body.desc': 'Move speed +20%',
      'blessing.heavy_bolts.name': 'Heavy Bolts',
      'blessing.heavy_bolts.desc': 'Projectile size +35%',
      'blessing.vital_vow.name': 'Vital Vow',
      'blessing.vital_vow.desc': 'Max HP +20',
      'blessing.iron_sacrament.name': 'Iron Sacrament',
      'blessing.iron_sacrament.desc': 'Damage taken -12%',
      'curse.frail_flesh.name': 'Frail Flesh',
      'curse.frail_flesh.desc': 'Max HP -20%',
      'curse.thin_blood.name': 'Thin Blood',
      'curse.thin_blood.desc': 'Healing received -50%',
      'curse.lead_feet.name': 'Lead Feet',
      'curse.lead_feet.desc': 'Move speed -12%',
      'curse.heavy_lungs.name': 'Heavy Lungs',
      'curse.heavy_lungs.desc': 'Dash cooldown +35%',
      'curse.hardy_foes.name': 'Hardy Foes',
      'curse.hardy_foes.desc': 'Enemy HP +25%',
      'boon.multishot.name': 'Multishot',
      'boon.multishot.desc': 'Projectiles +1. Shots spread into a fan.',
      'boon.ember_dash.name': 'Ember Dash',
      'boon.ember_dash.desc':
          'Dash leaves stronger burning ground. Stacks increase radius and damage.',
      'boon.cursed_aura.name': 'Cursed Aura',
      'boon.cursed_aura.desc':
          'Nearby enemies take visible aura damage. Stacks increase radius and damage.',
      'relic.hungry_chalice.name': 'Hungry Chalice',
      'relic.hungry_chalice.desc':
          'Kills grant double Essence, but healing is blocked.',
      'relic.broken_clock.name': 'Broken Clock',
      'relic.broken_clock.desc': 'Dash cooldown -45%, but max HP -15%.',
      'relic.contract_seal.name': 'Contract Seal',
      'relic.contract_seal.desc':
          'First pact curse is ignored, but you start cursed.',
      'blessing.hunter_pulse.name': 'Hunter Pulse',
      'blessing.hunter_pulse.desc': 'Projectile speed +25%',
      'blessing.blood_spark.name': 'Blood Spark',
      'blessing.blood_spark.desc': 'Heal 3 HP when killing an enemy',
      'blessing.sure_strike.name': 'Sure Strike',
      'blessing.sure_strike.desc': 'Critical chance +15%',
      'curse.open_wounds.name': 'Open Wounds',
      'curse.open_wounds.desc': 'Damage taken +25%',
      'curse.shaking_hands.name': 'Shaking Hands',
      'curse.shaking_hands.desc': 'Attack speed -15%',
      'curse.brittle_bolts.name': 'Brittle Bolts',
      'curse.brittle_bolts.desc': 'Projectile speed -18%',
      'boon.pierce.name': 'Pierce',
      'boon.pierce.desc':
          'Projectiles pierce +1 enemy. Stacks add more pierce.',
      'boon.chain.name': 'Chain',
      'boon.chain.desc':
          'Projectiles chain to +1 nearby enemy. Stacks add chains and range.',
      'boon.execute.name': 'Execute',
      'boon.execute.desc':
          'Projectiles instantly kill low-HP enemies. Stacks raise the threshold.',
      'boon.aegis.name': 'Aegis',
      'boon.aegis.desc':
          'Periodically blocks one hit. Stacks reduce recharge time.',
      'boon.slow_field.name': 'Slow Field',
      'boon.slow_field.desc':
          'Taking damage slows nearby enemies. Stacks improve strength and duration.',
      'relic.cursed_crown.name': 'Cursed Crown',
      'relic.cursed_crown.desc':
          'Each curse gives damage, but damage taken rises.',
      'relic.calamity_seal.name': 'Calamity Seal',
      'relic.calamity_seal.desc':
          'Each curse greatly raises damage. You start cursed.',
      'relic.full_moon_cup.name': 'Full Moon Cup',
      'relic.full_moon_cup.desc': 'Kills heal +4 HP, but max HP -15%.',
      'relic.runaway_heart.name': 'Runaway Heart',
      'relic.runaway_heart.desc':
          'Moving grants speed and attack speed. Standing still increases damage taken.',
      'relic.rift_eye.name': 'Rift Eye',
      'relic.rift_eye.desc':
          'Critical chance and damage rise, but base attack falls.',
      'relic.void_hand.name': 'Void Hand',
      'relic.void_hand.desc':
          'Dash farther and invulnerability lasts longer, but cooldown rises.',
      'relic.collector_scale.name': "Collector's Scale",
      'relic.collector_scale.desc':
          'Essence from kills +75%, but starting max HP -12%.',
      'relic.martyr_nail.name': "Martyr's Nail",
      'relic.martyr_nail.desc':
          'Missing HP raises damage and attack speed. Healing is halved.',
      'relic.echo_bell.name': 'Echo Bell',
      'relic.echo_bell.desc':
          'Boss Boon choices +1, but base damage is slightly reduced.',
    },
    AppLocale.ko: {
      'app.title': '무저의 저주',
      'app.tagline':
          '\uBAA8\uB4E0 \uCD95\uBCF5\uC5D0\uB294 \uC800\uC8FC\uAC00 \uBB36\uC778\uB2E4.',
      'ui.title.start': '\uC2DC\uC791',
      'ui.title.loading': '\uBD88\uB7EC\uC624\uB294 \uC911...',
      'ui.title.unlock': '\uD574\uAE08',
      'ui.title.codex': '회상록',
      'ui.title.settings': '\uC124\uC815',
      'ui.title.quit': '\uC885\uB8CC',
      'ui.meta.sigils': '\uAC01\uC778',
      'ui.meta.best_floor': '\uCD5C\uACE0 \uCE35',
      'ui.meta.runs': '\uB7F0',
      'ui.settings.language': '\uC5B8\uC5B4',
      'ui.settings.english': '\uC601\uC5B4',
      'ui.settings.korean': '\uD55C\uAD6D\uC5B4',
      'ui.settings.bgm_volume': 'BGM \uC74C\uB7C9',
      'ui.settings.combat_feedback': '\uC804\uD22C \uD53C\uB4DC\uBC31',
      'ui.settings.screen_shake': '\uD654\uBA74 \uD754\uB4E4\uB9BC',
      'ui.settings.offscreen_warnings': '\uD654\uBA74 \uBC16 \uACBD\uACE0',
      'ui.common.close': '\uB2EB\uAE30',
      'ui.common.owned': '\uBCF4\uC720',
      'ui.common.locked': '\uC7A0\uAE40',
      'ui.common.current': '\uD604\uC7AC',
      'ui.common.level': '\uB808\uBCA8',
      'ui.unlock.title': '\uD574\uAE08',
      'ui.unlock.stats': '\uC2A4\uD0EF',
      'ui.unlock.relics': '\uC720\uBB3C',
      'ui.unlock.boons': '\uAD8C\uB2A5',
      'ui.unlock.revival': '\uBD80\uD65C',
      'ui.unlock.stat_title': '\uB2A5\uB825\uCE58 \uAC15\uD654',
      'ui.unlock.stat_subtitle': '작은 영구 강화입니다. 상한이 있어 고층을 대신 밀어주진 않습니다.',
      'ui.unlock.relic_title': '\uC720\uBB3C \uD574\uAE08',
      'ui.unlock.relic_subtitle': '유물을 해금하고, 시작 후보 수를 늘립니다.',
      'ui.unlock.relic_choices': '\uC2DC\uC791 \uC720\uBB3C \uC120\uD0DD\uC9C0',
      'ui.unlock.relic_choices_desc': '{current}개 표시. 0이면 유물 없이 시작합니다.',
      'ui.unlock.boon_title': '\uD2B9\uC218 \uAD8C\uB2A5',
      'ui.unlock.boon_subtitle': '비싼 메타 강화입니다. 보스급 패시브로 시작합니다.',
      'ui.unlock.boon_active': '활성: 시작 시 무작위 보스 권능',
      'ui.unlock.boon_extra': '태그가 있어 시너지에 연결됩니다.',
      'ui.unlock.revival_title': '\uBD80\uD65C',
      'ui.unlock.revival_subtitle': '런마다 한 번 죽음을 막습니다. 대신 저주를 하나 받습니다.',
      'ui.unlock.revival_active':
          '\uD65C\uC131: \uB7F0\uB2F9 1\uD68C, \uCCB4\uB825 \uBC18 + \uBB34\uC791\uC704 \uC800\uC8FC',
      'ui.contract.title': '\uACC4\uC57D \uC120\uD0DD',
      'ui.contract.subtitle': '축복에는 늘 저주가 따릅니다. 힘에는 대가가 있습니다.',
      'ui.contract.blessing': '\uCD95\uBCF5',
      'ui.contract.curse': '\uC800\uC8FC',
      'ui.contract.bind': '선택',
      'ui.contract.preview_synergy': '\uC2DC\uB108\uC9C0',
      'ui.contract.preview_risk': '\uC704\uD5D8',
      'ui.boon.title': '\uBCF4\uC2A4 \uAD8C\uB2A5 \uC120\uD0DD',
      'ui.boon.subtitle': '쓰러진 수호자에게서 빼앗은 힘. 저주는 붙지 않습니다.',
      'ui.boon.label': '\uBCF4\uC2A4 \uAD8C\uB2A5',
      'ui.boon.claim': '선택',
      'ui.relic.title': '\uC2DC\uC791 \uC720\uBB3C \uC120\uD0DD',
      'ui.relic.subtitle': '첫 계약 전, 이번 런의 방향을 고릅니다.',
      'ui.relic.begin': '선택',
      'ui.memory.title': '기억의 방',
      'ui.memory.subtitle': '기억 조각 {order}',
      'ui.memory.subtitle_complete': '어둠 속에서 더는 새 기억이 떠오르지 않습니다.',
      'ui.memory.continue': '계속',
      'ui.inscription.title': '죄의 비문',
      'ui.inscription.prompt': 'E: 비문 읽기',
      'ui.codex.title': '회상록',
      'ui.codex.subtitle': '런을 거치며 되찾은 이야기 조각입니다.',
      'ui.codex.progress': '{revealed}/{total} 공개',
      'ui.codex.all': '전체',
      'ui.codex.memories': '기억',
      'ui.codex.inscriptions': '죄의 비문',
      'ui.codex.memory_number': '기억 {order}',
      'ui.codex.locked': '???',
      'ui.codex.locked_desc': '아직 떠오르지 않은 조각입니다.',
      'ui.codex.no_inscriptions': '아직 읽은 비문이 없습니다.',
      'ui.hud.essence': '\uC815\uC218',
      'ui.hud.floor': '\uCE35',
      'ui.hud.room': '\uBC29',
      'ui.hud.kills': '\uCC98\uCE58',
      'ui.hud.curses': '\uC800\uC8FC',
      'ui.hud.relic': '\uC720\uBB3C',
      'ui.hud.boss_favor': '계단 전까지 정수 x{multiplier}',
      'ui.hud.revival_ready': '부활 가능: 체력 절반 + 무작위 저주',
      'ui.hud.revival_spent': '부활 사용',
      'ui.hud.controls': '연출 {juice}   흔들림 {shake}   Tab/B 빌드   Esc 일시정지',
      'ui.hud.boss_room': '보스 방. 저주가 많을수록 공격이 빨라집니다.',
      'ui.hud.room_cleared': '클리어. 제단에서 계약하거나 열린 문으로 이동하세요.',
      'ui.result.died': '\uC0AC\uB9DD',
      'ui.result.abandoned': '\uB7F0 \uD3EC\uAE30',
      'ui.result.highest_floor': '\uCD5C\uACE0 \uB3C4\uB2EC \uCE35',
      'ui.result.ended_floor': '\uC885\uB8CC \uCE35',
      'ui.result.room': '\uBC29',
      'ui.result.kills': '\uCC98\uCE58',
      'ui.result.curses': '\uC800\uC8FC',
      'ui.result.relic': '\uC720\uBB3C',
      'ui.result.none': '\uC5C6\uC74C',
      'ui.result.curse_bonus': '\uC800\uC8FC \uBCF4\uB108\uC2A4',
      'ui.result.sigils_earned': '\uD68D\uB4DD \uAC01\uC778',
      'ui.result.record': '\uAE30\uB85D',
      'ui.result.new_best_score': '\uC2E0\uAE30\uB85D \uC810\uC218',
      'ui.result.depth': '\uC2EC\uB3C4',
      'ui.result.new_best_floor': '\uCD5C\uACE0 \uCE35 \uC2E0\uAE30\uB85D',
      'ui.result.score': '\uC810\uC218',
      'ui.result.restart': '재시작',
      'ui.summary.title': '\uBE4C\uB4DC \uC694\uC57D',
      'ui.pause.title': '런 정보',
      'ui.section.stats': '\uB2A5\uB825\uCE58',
      'ui.section.run': '\uB7F0',
      'ui.section.relic': '\uC720\uBB3C',
      'ui.section.boss_boons': '\uBCF4\uC2A4 \uAD8C\uB2A5',
      'ui.section.blessings': '\uCD95\uBCF5',
      'ui.section.curses': '\uC800\uC8FC',
      'ui.section.synergies': '\uC2DC\uB108\uC9C0',
      'ui.section.conflicts': '\uCDA9\uB3CC',
      'ui.section.settings': '\uC124\uC815',
      'ui.section.controls': '\uC870\uC791',
      'ui.empty.default': '없음.',
      'ui.empty.boss_boons':
          '\uC544\uC9C1 \uBCF4\uC2A4 \uAD8C\uB2A5\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      'ui.empty.blessings':
          '\uC544\uC9C1 \uCD95\uBCF5\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      'ui.empty.curses':
          '\uC544\uC9C1 \uC800\uC8FC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
      'ui.empty.synergies':
          '\uD65C\uC131 \uC2DC\uB108\uC9C0\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
      'ui.empty.conflicts':
          '\uD65C\uC131 \uCDA9\uB3CC\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      'ui.action.resume': '\uC7AC\uAC1C',
      'ui.action.abandon': '포기',
      'ui.stat.max_hp': '\uCD5C\uB300 \uCCB4\uB825',
      'ui.stat.move_speed': '\uC774\uB3D9 \uC18D\uB3C4',
      'ui.stat.attack_damage': '\uACF5\uACA9\uB825',
      'ui.stat.attack_speed': '\uACF5\uACA9 \uC18D\uB3C4',
      'ui.stat.dash_distance': '\uB300\uC2DC \uAC70\uB9AC',
      'ui.stat.dash_cooldown': '\uB300\uC2DC \uC7AC\uC0AC\uC6A9',
      'ui.stat.projectile_speed': '\uD22C\uC0AC\uCCB4 \uC18D\uB3C4',
      'ui.stat.projectile_size': '\uD22C\uC0AC\uCCB4 \uD06C\uAE30',
      'ui.stat.critical': '\uCE58\uBA85\uD0C0',
      'ui.stat.healing': '\uD68C\uBCF5',
      'ui.stat.damage_taken': '\uBC1B\uB294 \uD53C\uD574',
      'ui.stat.enemy_hp': '\uC801 \uCCB4\uB825',
      'ui.stat.heal_on_kill': '\uCC98\uCE58 \uD68C\uBCF5',
      'ui.stat.current_floor': '\uD604\uC7AC \uCE35',
      'ui.stat.highest_floor': '\uCD5C\uACE0 \uCE35',
      'ui.stat.room_visits': '\uBC29 \uBC29\uBB38',
      'ui.stat.room_type': '\uBC29 \uC720\uD615',
      'ui.stat.elapsed': '\uACBD\uACFC \uC2DC\uAC04',
      'ui.stat.damage': '\uD53C\uD574',
      'ui.stat.move': '\uC774\uB3D9',
      'ui.stat.hp': '\uCCB4\uB825',
      'ui.stat.score': '\uC810\uC218',
      'ui.stat.kills': '\uCC98\uCE58',
      'ui.stat.essence': '\uC815\uC218',
      'ui.stat.sigils': '\uAC01\uC778',
      'ui.stat.shake': '\uD754\uB4E4\uB9BC',
      'ui.status.dead_phase': '사망했습니다. 곧 결과 화면이 표시됩니다.',
      'ui.help.move': 'WASD / \uBC29\uD5A5\uD0A4: \uC774\uB3D9',
      'ui.help.dash': 'Space / Shift: \uB300\uC2DC',
      'ui.help.shoot': '\uB9C8\uC6B0\uC2A4 \uD074\uB9AD: \uC0AC\uACA9',
      'ui.help.build': 'Tab / B: \uBE4C\uB4DC \uC694\uC57D',
      'ui.help.pause': 'Esc: \uC7AC\uAC1C / \uC77C\uC2DC\uC815\uC9C0',
      'ui.help.build_close': 'Tab/B: 닫기   Esc: 일시정지',
      'synergy.glass_cannon.name': '\uC720\uB9AC \uB300\uD3EC',
      'synergy.glass_cannon.desc':
          '\uCCB4\uB825\uC774 \uB0AE\uC744\uC218\uB85D \uACF5\uACA9\uB825\uC774 \uC99D\uAC00\uD569\uB2C8\uB2E4.',
      'synergy.rush_slayer.name': '\uC9C8\uC8FC \uD559\uC0B4\uC790',
      'synergy.rush_slayer.desc':
          '\uC774\uB3D9 \uC911 \uACF5\uACA9\uB825\uACFC \uACF5\uACA9 \uC18D\uB3C4\uAC00 \uC99D\uAC00\uD569\uB2C8\uB2E4.',
      'synergy.fire_chain.name': '\uD654\uC5FC \uC5F0\uC1C4',
      'synergy.fire_chain.desc':
          '\uD22C\uC0AC\uCCB4\uAC00 \uD53C\uD574\uB97C \uC8FC\uB294 \uBD88\uAE38\uC744 \uB0A8\uAE41\uB2C8\uB2E4.',
      'synergy.reapers_deal.name': '\uC0AC\uC2E0\uC758 \uAC70\uB798',
      'synergy.reapers_deal.desc':
          '\uCC98\uCE58 \uC2DC \uC9E7\uC740 \uBB34\uC801\uACFC \uC18D\uB3C4\uB97C \uC5BB\uC2B5\uB2C8\uB2E4.',
      'conflict.bleeding_debt.name': '\uD53C\uC758 \uBD80\uCC44',
      'conflict.bleeding_debt.desc':
          '\uD68C\uBCF5\uC774 \uC57D\uD574\uC9C0\uACE0 \uBC1B\uB294 \uD53C\uD574\uAC00 \uB354 \uC2EC\uD574\uC9D1\uB2C8\uB2E4.',
      'room.start': '\uC2DC\uC791',
      'room.normal': '\uC77C\uBC18',
      'room.treasure': '\uBCF4\uBB3C',
      'room.miniboss': '\uC911\uAC04 \uBCF4\uC2A4',
      'room.elite': '\uC815\uC608',
      'room.challenge': '\uB3C4\uC804',
      'room.merchant': '\uACF5\uBB3C',
      'room.offering': '\uACF5\uBB3C',
      'room.upstairs': '\uACC4\uB2E8',
      'room.memory': '기억',
      'room.boss': '\uBCF4\uC2A4',
      'ui.offering.title': '\uC81C\uBB3C\uC758 \uC81C\uB2E8',
      'ui.offering.essence': '\uC815\uC218: {amount}',
      'ui.offering.cleanse': '저주 지우기',
      'ui.offering.cleanse_named': '저주 지우기: {name}',
      'ui.offering.no_curse': '지울 저주가 없습니다.',
      'ui.offering.cleanse_cost': '정수 {cost} 소모. 시너지/충돌을 다시 계산합니다.',
      'ui.offering.deeper': '깊은 계약',
      'ui.offering.deeper_spent': '깊은 계약: 완료',
      'ui.offering.deeper_spent_desc': '이 제단은 이미 피를 받았습니다.',
      'ui.offering.deeper_desc': '{blessing} 획득, {curse} 추가. 무료.',
      'ui.offering.blessing': '축복 구매: {name}',
      'ui.offering.blessing_claimed': '축복 구매: 완료',
      'ui.offering.blessing_claimed_desc': '이미 받은 축복입니다.',
      'ui.offering.blessing_desc': '{description} (\uC815\uC218 {price})',
      'ui.offering.reroll': '다시 뽑기',
      'ui.offering.reroll_desc': '정수 {cost}로 목록과 속삭임을 새로 뽑습니다.',
      'ui.offering.step_away': '나가기',
      'story.memory.01': '제단에 오르던 날, 모두가 영광이라 말했다. 장례라는 걸 아는 건 떨리는 네 손뿐이었다.',
      'story.memory.02': '동료들은 눈을 피했다. 주머니는 무거웠고, 기도 소리는 네 이름보다 컸다.',
      'story.memory.03': '교단은 너를 선택받았다고 불렀다. 팔렸다고 말하는 것보다 듣기 좋았으니까.',
      'story.memory.04':
          '구덩이 바닥에서 얼굴 없는 무언가가 웃었다. 그것은 위로 올라가는 길을 제안했다. 저주 하나씩.',
      'story.memory.05': '층을 오를수록 피는 낯선 형태를 배웠다. 두려워하던 괴물이 네 목소리에 대답하기 시작했다.',
      'story.memory.06':
          '너는 대답 없는 지상을 향해 오른다. 어쩌면 제단은 아래가 아니라, 처음부터 앞에 있었는지도 모른다.',
      'story.memory.complete': '방은 조용하다. 돌려받을 기억은 이미 모두 가져갔다.',
      'story.memory.already_claimed': '희미한 메아리만 남았다. 이 방의 기억은 이미 되찾았다.',
      'story.sin.abandonment.01': '버려진 자는 닫힌 문들의 모양을 모두 기억한다.',
      'story.sin.abandonment.02': '친구들이 잊은 이름은 어떤 기도보다 크게 울린다.',
      'story.sin.greed.01': '금화는 자비를 사지 못한다. 배신이 웃는 법만 가르칠 뿐.',
      'story.sin.greed.02': '그들의 손은 동전을 셀 때 떨렸다. 죄책감이 아니라 허기 때문이었다.',
      'story.sin.betrayal.01': '가장 깊은 상처는 네가 믿은 곳을 아는 손이 낸다.',
      'story.sin.betrayal.02': '침묵 속에서 깨진 맹세도 결국 제단에 닿는다.',
      'story.sin.fanaticism.01': '믿음은 칼을 벼리고, 피를 증거라 부른다.',
      'story.sin.fanaticism.02': '그들은 비명을 듣지 않으려 제물을 찬양했다.',
      'story.sin.pride.01': '교만한 자는 계단을 쌓고, 높이를 속죄라 착각한다.',
      'story.sin.pride.02': '끝없는 등반도 어떤 면에서는 무릎 꿇음이다.',
      'tag.movement': '\uC774\uB3D9',
      'tag.health': '\uCCB4\uB825',
      'tag.projectile': '\uD22C\uC0AC\uCCB4',
      'tag.melee': '\uADFC\uC811',
      'tag.fire': '\uD654\uC5FC',
      'tag.onKill': '\uCC98\uCE58',
      'tag.onHit': '\uD53C\uACA9',
      'tag.lowHp': '\uC800\uCCB4\uB825',
      'tag.risk': '\uC704\uD5D8',
      'blessing.quick_hands.name': '\uB0A0\uC36C \uC190\uB180\uB9BC',
      'blessing.quick_hands.desc': '\uACF5\uACA9 \uC18D\uB3C4 +30%',
      'blessing.sharpened_will.name': '\uB0A0\uCE74\uB85C\uC6B4 \uC758\uC9C0',
      'blessing.sharpened_will.desc': '\uACF5\uACA9\uB825 +25%',
      'blessing.long_step.name': '\uAE34 \uBCF4\uD3ED',
      'blessing.long_step.desc': '\uB300\uC2DC \uAC70\uB9AC +30%',
      'blessing.fleet_body.name': '\uAC00\uBCBC\uC6B4 \uC721\uCCB4',
      'blessing.fleet_body.desc': '\uC774\uB3D9 \uC18D\uB3C4 +20%',
      'blessing.heavy_bolts.name': '\uBB35\uC9C1\uD55C \uD0C4\uD658',
      'blessing.heavy_bolts.desc': '\uD22C\uC0AC\uCCB4 \uD06C\uAE30 +35%',
      'blessing.vital_vow.name': '\uC0DD\uBA85\uC758 \uB9F9\uC138',
      'blessing.vital_vow.desc': '\uCD5C\uB300 \uCCB4\uB825 +20',
      'blessing.iron_sacrament.name': '\uCCA0\uC758 \uC131\uCC2C',
      'blessing.iron_sacrament.desc': '\uBC1B\uB294 \uD53C\uD574 -12%',
      'curse.frail_flesh.name': '\uC57D\uD574\uC9C4 \uC721\uC2E0',
      'curse.frail_flesh.desc': '\uCD5C\uB300 \uCCB4\uB825 -20%',
      'curse.thin_blood.name': '\uBB3D\uC740 \uD53C',
      'curse.thin_blood.desc': '\uBC1B\uB294 \uD68C\uBCF5 -50%',
      'curse.lead_feet.name': '\uB0A9\uCC98\uB7FC \uBB34\uAC70\uC6B4 \uBC1C',
      'curse.lead_feet.desc': '\uC774\uB3D9 \uC18D\uB3C4 -12%',
      'curse.heavy_lungs.name': '\uBB34\uAC70\uC6B4 \uD3D0',
      'curse.heavy_lungs.desc': '\uB300\uC2DC \uC7AC\uC0AC\uC6A9 +35%',
      'curse.hardy_foes.name': '\uAC15\uC778\uD55C \uC801',
      'curse.hardy_foes.desc': '\uC801 \uCCB4\uB825 +25%',
      'boon.multishot.name': '\uB2E4\uC911 \uC0AC\uACA9',
      'boon.multishot.desc':
          '\uD22C\uC0AC\uCCB4 +1. \uBD80\uCC44\uAF34\uB85C \uD37C\uC9D1\uB2C8\uB2E4.',
      'boon.ember_dash.name': '\uC794\uC5FC \uB300\uC2DC',
      'boon.ember_dash.desc':
          '\uB300\uC2DC\uAC00 \uB354 \uAC15\uD55C \uBD88\uAE38\uC744 \uB0A8\uAE41\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uBC94\uC704\uC640 \uD53C\uD574\uAC00 \uC99D\uAC00\uD569\uB2C8\uB2E4.',
      'boon.cursed_aura.name': '\uC800\uC8FC\uC758 \uC624\uB77C',
      'boon.cursed_aura.desc':
          '\uC8FC\uBCC0 \uC801\uC5D0\uAC8C \uBCF4\uC774\uB294 \uC624\uB77C \uD53C\uD574\uB97C \uC90D\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uBC94\uC704\uC640 \uD53C\uD574\uAC00 \uC99D\uAC00\uD569\uB2C8\uB2E4.',
      'relic.hungry_chalice.name': '\uAD76\uC8FC\uB9B0 \uC131\uBC30',
      'relic.hungry_chalice.desc':
          '\uCC98\uCE58 \uC815\uC218\uAC00 2\uBC30\uAC00 \uB418\uC9C0\uB9CC, \uD68C\uBCF5\uC774 \uCC28\uB2E8\uB429\uB2C8\uB2E4.',
      'relic.broken_clock.name': '\uAE68\uC9C4 \uC2DC\uACC4',
      'relic.broken_clock.desc':
          '\uB300\uC2DC \uC7AC\uC0AC\uC6A9 -45%, \uCD5C\uB300 \uCCB4\uB825 -15%.',
      'relic.contract_seal.name': '\uACC4\uC57D\uC758 \uC778\uC7A5',
      'relic.contract_seal.desc':
          '\uCCAB \uACC4\uC57D \uC800\uC8FC\uB97C \uBB34\uD6A8\uD654\uD558\uC9C0\uB9CC, \uC800\uC8FC\uB97C \uC548\uACE0 \uC2DC\uC791\uD569\uB2C8\uB2E4.',
      'blessing.hunter_pulse.name': '\uC0AC\uB0E5\uAFBC\uC758 \uB9E5\uB3D9',
      'blessing.hunter_pulse.desc': '\uD22C\uC0AC\uCCB4 \uC18D\uB3C4 +25%',
      'blessing.blood_spark.name': '\uD53C\uC758 \uBD88\uAF43',
      'blessing.blood_spark.desc':
          '\uC801 \uCC98\uCE58 \uC2DC \uCCB4\uB825 3 \uD68C\uBCF5',
      'blessing.sure_strike.name': '\uD655\uC2E4\uD55C \uC77C\uACA9',
      'blessing.sure_strike.desc': '\uCE58\uBA85\uD0C0 \uD655\uB960 +15%',
      'curse.open_wounds.name': '\uBC8C\uC5B4\uC9C4 \uC0C1\uCC98',
      'curse.open_wounds.desc': '\uBC1B\uB294 \uD53C\uD574 +25%',
      'curse.shaking_hands.name': '\uB5A8\uB9AC\uB294 \uC190',
      'curse.shaking_hands.desc': '\uACF5\uACA9 \uC18D\uB3C4 -15%',
      'curse.brittle_bolts.name': '\uCDE8\uC57D\uD55C \uD0C4\uD658',
      'curse.brittle_bolts.desc': '\uD22C\uC0AC\uCCB4 \uC18D\uB3C4 -18%',
      'boon.pierce.name': '\uAD00\uD1B5',
      'boon.pierce.desc':
          '\uD22C\uC0AC\uCCB4\uAC00 \uC801 +1\uBA85\uC744 \uAD00\uD1B5\uD569\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uAD00\uD1B5\uC774 \uB298\uC5B4\uB0A9\uB2C8\uB2E4.',
      'boon.chain.name': '\uC5F0\uC1C4',
      'boon.chain.desc':
          '\uD22C\uC0AC\uCCB4\uAC00 \uC8FC\uBCC0 \uC801 +1\uBA85\uC5D0\uAC8C \uD280\uC5B4\uAC11\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uD69F\uC218\uC640 \uAC70\uB9AC\uAC00 \uB298\uC5B4\uB0A9\uB2C8\uB2E4.',
      'boon.execute.name': '\uCC98\uD615',
      'boon.execute.desc':
          '\uC800\uCCB4\uB825 \uC801\uC744 \uC989\uC2DC \uCC98\uCE58\uD569\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uAE30\uC900\uC774 \uB192\uC544\uC9D1\uB2C8\uB2E4.',
      'boon.aegis.name': '\uC218\uD638 \uBC29\uD328',
      'boon.aegis.desc':
          '\uC8FC\uAE30\uC801\uC73C\uB85C \uD53C\uD574 1\uD68C\uB97C \uBB34\uD6A8\uD654\uD569\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uC7AC\uCDA9\uC804\uC774 \uBE68\uB77C\uC9D1\uB2C8\uB2E4.',
      'boon.slow_field.name': '\uC2DC\uAC04 \uC65C\uACE1',
      'boon.slow_field.desc':
          '\uD53C\uACA9 \uC2DC \uC8FC\uBCC0 \uC801\uC744 \uB290\uB9AC\uAC8C \uD569\uB2C8\uB2E4. \uC911\uCCA9\uC2DC \uAC15\uB3C4\uC640 \uC9C0\uC18D\uC2DC\uAC04\uC774 \uC99D\uAC00\uD569\uB2C8\uB2E4.',
      'relic.cursed_crown.name': '\uC800\uC8FC\uBC1B\uC740 \uC655\uAD00',
      'relic.cursed_crown.desc':
          '\uC800\uC8FC\uB9C8\uB2E4 \uACF5\uACA9\uB825\uC774 \uC99D\uAC00\uD558\uC9C0\uB9CC, \uBC1B\uB294 \uD53C\uD574\uB3C4 \uB298\uC5B4\uB0A9\uB2C8\uB2E4.',
      'relic.calamity_seal.name': '\uC7AC\uC559\uC758 \uC778\uC7A5',
      'relic.calamity_seal.desc':
          '\uC800\uC8FC\uB9C8\uB2E4 \uACF5\uACA9\uB825\uC774 \uD06C\uAC8C \uC99D\uAC00\uD569\uB2C8\uB2E4. \uC800\uC8FC\uB97C \uC548\uACE0 \uC2DC\uC791\uD569\uB2C8\uB2E4.',
      'relic.full_moon_cup.name': '\uB9CC\uC6D4\uC758 \uC794',
      'relic.full_moon_cup.desc':
          '\uCC98\uCE58 \uC2DC \uCCB4\uB825 +4 \uD68C\uBCF5, \uCD5C\uB300 \uCCB4\uB825 -15%.',
      'relic.runaway_heart.name': '\uD3ED\uC8FC\uD558\uB294 \uC2EC\uC7A5',
      'relic.runaway_heart.desc':
          '\uC774\uB3D9 \uC911 \uC18D\uB3C4\uC640 \uACF5\uACA9 \uC18D\uB3C4\uAC00 \uC99D\uAC00\uD558\uACE0, \uC815\uC9C0 \uC911 \uBC1B\uB294 \uD53C\uD574\uAC00 \uB298\uC5B4\uB0A9\uB2C8\uB2E4.',
      'relic.rift_eye.name': '\uADE0\uC5F4\uC758 \uB208',
      'relic.rift_eye.desc':
          '\uCE58\uBA85\uD0C0 \uD655\uB960\uACFC \uD53C\uD574\uAC00 \uC99D\uAC00\uD558\uC9C0\uB9CC, \uAE30\uBCF8 \uACF5\uACA9\uB825\uC774 \uAC10\uC18C\uD569\uB2C8\uB2E4.',
      'relic.void_hand.name': '\uACF5\uD5C8\uC758 \uC190',
      'relic.void_hand.desc':
          '\uB300\uC2DC \uAC70\uB9AC\uC640 \uBB34\uC801\uC774 \uB298\uC9C0\uB9CC, \uC7AC\uC0AC\uC6A9\uB3C4 \uB298\uC5B4\uB0A9\uB2C8\uB2E4.',
      'relic.collector_scale.name': '\uC218\uC9D1\uAC00\uC758 \uCC9C\uCE6D',
      'relic.collector_scale.desc':
          '\uCC98\uCE58 \uC815\uC218 +75%, \uC2DC\uC791 \uCD5C\uB300 \uCCB4\uB825 -12%.',
      'relic.martyr_nail.name': '\uC21C\uAD50\uC790\uC758 \uBABB',
      'relic.martyr_nail.desc':
          '\uC783\uC740 \uCCB4\uB825\uC774 \uB9CE\uC744\uC218\uB85D \uACF5\uACA9\uB825\uACFC \uACF5\uACA9 \uC18D\uB3C4\uAC00 \uC99D\uAC00\uD558\uACE0, \uD68C\uBCF5 \uD6A8\uC728\uC774 \uBC18\uAC10\uB429\uB2C8\uB2E4.',
      'relic.echo_bell.name': '\uBA54\uC544\uB9AC\uC758 \uC885',
      'relic.echo_bell.desc':
          '\uBCF4\uC2A4 \uAD8C\uB2A5 \uC120\uD0DD\uC9C0 +1, \uAE30\uBCF8 \uACF5\uACA9\uB825\uC774 \uC18C\uD3ED \uAC10\uC18C\uD569\uB2C8\uB2E4.',
    },
  };
}
