import 'game_modifier.dart';

class Blessing extends GameModifier {
  const Blessing({
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

final List<Blessing> blessingTable = [
  Blessing(
    id: 'quick_hands',
    name: 'Quick Hands',
    description: 'Attack speed +30%',
    tags: {EffectTag.projectile},
    onAcquireEffect: (ctx) => ctx.gameState.stats.attackSpeed *= 1.3,
  ),
  Blessing(
    id: 'sharpened_will',
    name: 'Sharpened Will',
    description: 'Attack damage +25%',
    tags: {EffectTag.onHit, EffectTag.onKill, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.attackDamage *= 1.25,
  ),
  Blessing(
    id: 'long_step',
    name: 'Long Step',
    description: 'Dash distance +30%',
    tags: {EffectTag.movement},
    onAcquireEffect: (ctx) => ctx.gameState.stats.dashDistance *= 1.3,
  ),
  Blessing(
    id: 'fleet_body',
    name: 'Fleet Body',
    description: 'Move speed +20%',
    tags: {EffectTag.movement},
    onAcquireEffect: (ctx) => ctx.gameState.stats.moveSpeed *= 1.2,
  ),
  Blessing(
    id: 'heavy_bolts',
    name: 'Heavy Bolts',
    description: 'Projectile size +35%',
    tags: {EffectTag.projectile},
    onAcquireEffect: (ctx) => ctx.gameState.stats.projectileRadius *= 1.35,
  ),
  Blessing(
    id: 'vital_vow',
    name: 'Vital Vow',
    description: 'Max HP +20',
    tags: {EffectTag.health},
    onAcquireEffect: (ctx) => ctx.gameState.stats.maxHp += 20,
  ),
  Blessing(
    id: 'iron_sacrament',
    name: 'Iron Sacrament',
    description: 'Damage taken -12%',
    tags: {EffectTag.health, EffectTag.onHit},
    onAcquireEffect: (ctx) => ctx.gameState.stats.damageTakenMultiplier *= 0.88,
  ),
  Blessing(
    id: 'hunter_pulse',
    name: 'Hunter Pulse',
    description: 'Projectile speed +25%',
    tags: {EffectTag.projectile},
    onAcquireEffect: (ctx) => ctx.gameState.stats.projectileSpeed *= 1.25,
  ),
  Blessing(
    id: 'blood_spark',
    name: 'Blood Spark',
    description: 'Heal 3 HP when killing an enemy',
    tags: {EffectTag.health, EffectTag.onKill, EffectTag.fire},
    onAcquireEffect: (ctx) => ctx.gameState.stats.healOnKill += 3,
  ),
  Blessing(
    id: 'sure_strike',
    name: 'Sure Strike',
    description: 'Critical chance +15%',
    tags: {EffectTag.onHit, EffectTag.lowHp, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.criticalChance += 0.15,
  ),
];
