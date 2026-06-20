import 'game_modifier.dart';

class BossBoon extends GameModifier {
  const BossBoon({
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

final List<BossBoon> bossBoonTable = [
  BossBoon(
    id: 'multishot',
    name: 'Multishot',
    description: 'Projectiles +1. Shots spread into a fan.',
    tags: {EffectTag.projectile, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.projectileCount += 1;
      ctx.gameState.stats.projectileSpread += 0.08;
    },
  ),
  BossBoon(
    id: 'ember_dash',
    name: 'Ember Dash',
    description:
        'Dash leaves stronger burning ground. Stacks increase radius and damage.',
    tags: {EffectTag.movement, EffectTag.fire},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.dashLeavesFire = true;
      ctx.gameState.stats.dashFireDamage += 5;
      ctx.gameState.stats.dashFireRadius += 5;
    },
  ),
  BossBoon(
    id: 'cursed_aura',
    name: 'Cursed Aura',
    description:
        'Nearby enemies take visible aura damage. Stacks increase radius and damage.',
    tags: {EffectTag.health, EffectTag.onHit, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.auraDamage += 7;
      ctx.gameState.stats.auraRadius += 18;
    },
  ),
  BossBoon(
    id: 'pierce',
    name: 'Pierce',
    description: 'Projectiles pierce +1 enemy. Stacks add more pierce.',
    tags: {EffectTag.projectile, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.projectilePierce += 1;
    },
  ),
  BossBoon(
    id: 'chain',
    name: 'Chain',
    description:
        'Projectiles chain to +1 nearby enemy. Stacks add chains and range.',
    tags: {EffectTag.projectile, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.chainCount += 1;
      ctx.gameState.stats.chainRange += 35;
    },
  ),
  BossBoon(
    id: 'execute',
    name: 'Execute',
    description:
        'Projectiles instantly kill low-HP enemies. Stacks raise the threshold.',
    tags: {EffectTag.onHit, EffectTag.lowHp, EffectTag.risk},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.executeThreshold += 0.08;
    },
  ),
  BossBoon(
    id: 'aegis',
    name: 'Aegis',
    description: 'Periodically blocks one hit. Stacks reduce recharge time.',
    tags: {EffectTag.health, EffectTag.onHit},
    onAcquireEffect: (ctx) {
      final current = ctx.gameState.stats.aegisCooldown;
      ctx.gameState.stats.aegisCooldown = current <= 0
          ? 14
          : (current - 2).clamp(6, 14);
    },
  ),
  BossBoon(
    id: 'slow_field',
    name: 'Slow Field',
    description:
        'Taking damage slows nearby enemies. Stacks improve strength and duration.',
    tags: {EffectTag.health, EffectTag.onHit, EffectTag.movement},
    onAcquireEffect: (ctx) {
      ctx.gameState.stats.slowFieldStrength =
          (ctx.gameState.stats.slowFieldStrength - 0.12).clamp(0.42, 1.0);
      ctx.gameState.stats.slowFieldDuration += 0.7;
    },
  ),
];
