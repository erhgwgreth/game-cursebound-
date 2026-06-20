import '../components/enemy.dart';
import '../components/player.dart';
import '../game/game_state.dart';

enum EffectTag {
  movement,
  health,
  projectile,
  melee,
  fire,
  onKill,
  onHit,
  lowHp,
  risk,
}

class RunContext {
  const RunContext({
    required this.player,
    required this.gameState,
    required this.modifiers,
  });

  final Player player;
  final GameState gameState;
  final List<GameModifier> modifiers;
}

abstract class GameModifier {
  const GameModifier();

  String get id;
  String get name;
  String get description;
  Set<EffectTag> get tags;

  void onAcquire(RunContext ctx) {}

  void onAttack(RunContext ctx) {}

  void onHit(RunContext ctx, double damage) {}

  void onKill(RunContext ctx, Enemy enemy) {}

  void onUpdate(RunContext ctx, double dt) {}

  void onRoomClear(RunContext ctx) {}
}
