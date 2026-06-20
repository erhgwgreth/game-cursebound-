import 'game_modifier.dart';

class Curse extends GameModifier {
  const Curse({
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

final List<Curse> curseTable = [
  Curse(
    id: 'frail_flesh',
    name: 'Frail Flesh',
    description: 'Max HP -20%',
    tags: {EffectTag.health, EffectTag.lowHp, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.maxHp *= 0.8,
  ),
  Curse(
    id: 'thin_blood',
    name: 'Thin Blood',
    description: 'Healing received -50%',
    tags: {EffectTag.health, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.healingMultiplier *= 0.5,
  ),
  Curse(
    id: 'lead_feet',
    name: 'Lead Feet',
    description: 'Move speed -12%',
    tags: {EffectTag.movement},
    onAcquireEffect: (ctx) => ctx.gameState.stats.moveSpeed *= 0.88,
  ),
  Curse(
    id: 'heavy_lungs',
    name: 'Heavy Lungs',
    description: 'Dash cooldown +35%',
    tags: {EffectTag.movement, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.dashCooldown *= 1.35,
  ),
  Curse(
    id: 'hardy_foes',
    name: 'Hardy Foes',
    description: 'Enemy HP +25%',
    tags: {EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.enemyHealthMultiplier *= 1.25,
  ),
  Curse(
    id: 'open_wounds',
    name: 'Open Wounds',
    description: 'Damage taken +25%',
    tags: {EffectTag.onHit, EffectTag.health, EffectTag.risk},
    onAcquireEffect: (ctx) => ctx.gameState.stats.damageTakenMultiplier *= 1.25,
  ),
  Curse(
    id: 'shaking_hands',
    name: 'Shaking Hands',
    description: 'Attack speed -15%',
    tags: {EffectTag.projectile},
    onAcquireEffect: (ctx) => ctx.gameState.stats.attackSpeed *= 0.85,
  ),
  Curse(
    id: 'brittle_bolts',
    name: 'Brittle Bolts',
    description: 'Projectile speed -18%',
    tags: {EffectTag.projectile},
    onAcquireEffect: (ctx) => ctx.gameState.stats.projectileSpeed *= 0.82,
  ),
];
