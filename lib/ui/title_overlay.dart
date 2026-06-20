import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/cursebound_game.dart';

class TitleOverlay extends StatelessWidget {
  const TitleOverlay({required this.game, super.key});

  final CurseboundGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.metaProgress,
      builder: (context, _) {
        final meta = game.metaProgress;

        return Material(
          color: Colors.black.withValues(alpha: 0.82),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Cursebound',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD7B84F),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Every blessing binds a curse.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: 'Sigils', value: '${meta.sigils}'),
                        _MetaPill(
                          label: 'Best Floor',
                          value: '${meta.bestFloor}',
                        ),
                        _MetaPill(label: 'Runs', value: '${meta.totalRuns}'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _MenuButton(
                      label: meta.isLoaded ? 'Start' : 'Loading...',
                      primary: true,
                      onPressed: meta.isLoaded ? game.openRelicChoice : null,
                    ),
                    const SizedBox(height: 10),
                    _MenuButton(
                      label: 'Unlock',
                      onPressed: meta.isLoaded ? game.openUnlockScreen : null,
                    ),
                    const SizedBox(height: 10),
                    _MenuButton(
                      label: 'Settings',
                      onPressed: () => _showSettings(context),
                    ),
                    const SizedBox(height: 10),
                    _MenuButton(
                      label: 'Quit',
                      onPressed: () => SystemNavigator.pop(),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Debug: F7 grants +10 Sigils.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF12141C),
          title: const Text('Settings'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: game.juice.settings.enabled,
                    title: const Text('Combat feedback'),
                    onChanged: (value) {
                      setDialogState(() => game.juice.settings.enabled = value);
                    },
                  ),
                  SwitchListTile(
                    value: game.juice.settings.screenShakeEnabled,
                    title: const Text('Screen shake'),
                    onChanged: (value) {
                      setDialogState(
                        () => game.juice.settings.screenShakeEnabled = value,
                      );
                    },
                  ),
                  SwitchListTile(
                    value: game.juice.settings.offscreenIndicatorsEnabled,
                    title: const Text('Offscreen warnings'),
                    onChanged: (value) {
                      setDialogState(
                        () => game.juice.settings.offscreenIndicatorsEnabled =
                            value,
                      );
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: primary
              ? const Color(0xFFD7B84F)
              : const Color(0xFF21151A),
          foregroundColor: primary ? const Color(0xFF12100A) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(
            color: primary ? const Color(0xFFD7B84F) : Colors.white24,
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12141C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label $value',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
