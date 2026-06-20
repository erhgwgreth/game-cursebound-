import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/cursebound_game.dart';
import 'ui/boss_boon_overlay.dart';
import 'ui/build_summary_overlay.dart';
import 'ui/contract_overlay.dart';
import 'ui/hud.dart';
import 'ui/merchant_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/relic_overlay.dart';
import 'ui/result_overlay.dart';
import 'ui/route_overlay.dart';
import 'ui/title_overlay.dart';
import 'ui/unlock_overlay.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cursebound',
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CurseboundGame _game;
  late final FocusNode _gameFocusNode;

  @override
  void initState() {
    super.initState();
    _gameFocusNode = FocusNode(debugLabel: 'CurseboundGameFocus');
    _game = _createGame();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _gameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _gameFocusNode.dispose();
    super.dispose();
  }

  CurseboundGame _createGame() {
    return CurseboundGame(onRestart: _restartGame);
  }

  void _restartGame() {
    setState(() {
      _game = _createGame();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _gameFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _gameFocusNode.requestFocus(),
        child: GameWidget<CurseboundGame>(
          game: _game,
          focusNode: _gameFocusNode,
          autofocus: true,
          overlayBuilderMap: {
            'boss_boon': (context, game) => BossBoonOverlay(game: game),
            'build': (context, game) => BuildSummaryOverlay(game: game),
            'hud': (context, game) => HudOverlay(game: game),
            'contract': (context, game) => ContractOverlay(game: game),
            'merchant': (context, game) => MerchantOverlay(game: game),
            'pause': (context, game) => PauseOverlay(game: game),
            'relic': (context, game) => RelicOverlay(game: game),
            'route': (context, game) => RouteOverlay(game: game),
            'title': (context, game) => TitleOverlay(game: game),
            'unlock': (context, game) => UnlockOverlay(game: game),
            'result': (context, game) => ResultOverlay(game: game),
          },
        ),
      ),
    );
  }
}
