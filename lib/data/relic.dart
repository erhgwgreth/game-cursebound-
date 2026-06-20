import 'game_modifier.dart';

class Relic extends GameModifier {
  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.onAcquireEffect,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final Set<EffectTag> tags;
  final void Function(RunContext ctx) onAcquireEffect;

  @override
  void onAcquire(RunContext ctx) => onAcquireEffect(ctx);
}

final List<Relic> relicTable = [
  Relic(
    id: 'hungry_chalice',
    name: 'Hungry Chalice',
    description: 'Kills grant double Essence, but healing is blocked.',
    tags: {EffectTag.onKill, EffectTag.health, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.killEssenceMultiplier = 2;
      ctx.gameState.healingBlocked = true;
    },
  ),
  Relic(
    id: 'broken_clock',
    name: 'Broken Clock',
    description: 'Dash cooldown -45%, but max HP -15%.',
    tags: {EffectTag.movement, EffectTag.lowHp, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.dashCooldown *= 0.55;
      ctx.gameState.stats.maxHp *= 0.85;
    },
  ),
  Relic(
    id: 'contract_seal',
    name: 'Contract Seal',
    description: 'First pact curse is ignored, but you start cursed.',
    tags: {EffectTag.health, EffectTag.risk},
    onAcquireEffect: (_) {},
  ),
  Relic(
    id: 'cursed_crown',
    name: 'Cursed Crown',
    description: 'Each curse gives damage, but damage taken rises.',
    tags: {EffectTag.risk, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      final curseCount = ctx.gameState.curses.length;
      ctx.gameState.stats.attackDamage *= 1 + curseCount * 0.09;
      ctx.gameState.stats.damageTakenMultiplier *= 1.12;
    },
  ),
  Relic(
    id: 'calamity_seal',
    name: 'Calamity Seal',
    description: 'Each curse greatly raises damage. You start cursed.',
    tags: {EffectTag.risk, EffectTag.lowHp, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      final curseCount = ctx.gameState.curses.length;
      ctx.gameState.stats.attackDamage *= 1 + curseCount * 0.14;
    },
  ),
  Relic(
    id: 'full_moon_cup',
    name: 'Full Moon Cup',
    description: 'Kills heal +4 HP, but max HP -15%.',
    tags: {EffectTag.health, EffectTag.onKill, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.healOnKill += 4;
      ctx.gameState.stats.maxHp *= 0.85;
    },
  ),
  Relic(
    id: 'runaway_heart',
    name: 'Runaway Heart',
    description:
        'Moving grants speed and attack speed. Standing still increases damage taken.',
    tags: {EffectTag.movement, EffectTag.onHit, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.movingMoveSpeedMultiplier *= 1.14;
      ctx.gameState.stats.movingAttackSpeedMultiplier *= 1.22;
      ctx.gameState.stats.stationaryDamageTakenMultiplier *= 1.28;
    },
  ),
  Relic(
    id: 'rift_eye',
    name: 'Rift Eye',
    description: 'Critical chance and damage rise, but base attack falls.',
    tags: {EffectTag.onHit, EffectTag.lowHp, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.criticalChance += 0.22;
      ctx.gameState.stats.criticalMultiplier += 0.65;
      ctx.gameState.stats.attackDamage *= 0.82;
    },
  ),
  Relic(
    id: 'void_hand',
    name: 'Void Hand',
    description:
        'Dash farther and invulnerability lasts longer, but cooldown rises.',
    tags: {EffectTag.movement, EffectTag.lowHp},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.dashDistance *= 1.28;
      ctx.gameState.stats.dashInvincibleDuration += 0.12;
      ctx.gameState.stats.dashCooldown *= 1.22;
    },
  ),
  Relic(
    id: 'collector_scale',
    name: "Collector's Scale",
    description: 'Essence from kills +75%, but starting max HP -12%.',
    tags: {EffectTag.risk, EffectTag.onKill, EffectTag.health},
    onAcquireEffect: (ctx) {
      ctx.gameState.killEssenceMultiplier *= 1.75;
      ctx.gameState.stats.maxHp *= 0.88;
    },
  ),
  Relic(
    id: 'martyr_nail',
    name: "Martyr's Nail",
    description:
        'Missing HP raises damage and attack speed. Healing is halved.',
    tags: {EffectTag.lowHp, EffectTag.health, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.lowHpPowerMultiplier += 0.72;
      ctx.gameState.stats.healingMultiplier *= 0.5;
    },
  ),
  Relic(
    id: 'echo_bell',
    name: 'Echo Bell',
    description: 'Boss Boon choices +1, but base damage is slightly reduced.',
    tags: {EffectTag.projectile, EffectTag.onKill, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.bossBoonChoiceBonus += 1;
      ctx.gameState.stats.attackDamage *= 0.92;
    },
  ),
];
