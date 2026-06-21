import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/cursebound_game.dart';
import 'systems/localization_service.dart';
import 'ui/app_text.dart';
import 'ui/boss_boon_overlay.dart';
import 'ui/build_summary_overlay.dart';
import 'ui/codex_overlay.dart';
import 'ui/contract_overlay.dart';
import 'ui/hud.dart';
import 'ui/inscription_overlay.dart';
import 'ui/merchant_overlay.dart';
import 'ui/memory_room_overlay.dart';
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
    return AnimatedBuilder(
      animation: LocalizationService.instance,
      builder: (context, _) {
        final loc = LocalizationService.instance;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: loc.tr('app.title'),
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            textTheme: ThemeData.dark(
              useMaterial3: true,
            ).textTheme.apply(fontFamily: AppText.fontFamily),
            primaryTextTheme: ThemeData.dark(
              useMaterial3: true,
            ).primaryTextTheme.apply(fontFamily: AppText.fontFamily),
          ),
          home: const GameScreen(),
        );
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late CurseboundGame _game;
  late final FocusNode _gameFocusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _gameFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_game.bgm.resume());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_game.bgm.pause());
    }
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
            'codex': (context, game) => CodexOverlay(game: game),
            'hud': (context, game) => HudOverlay(game: game),
            'inscription': (context, game) => InscriptionOverlay(game: game),
            'contract': (context, game) => ContractOverlay(game: game),
            'merchant': (context, game) => MerchantOverlay(game: game),
            'memory_room': (context, game) => MemoryRoomOverlay(game: game),
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
