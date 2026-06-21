import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

enum BgmTrack { title, combat, boss1, boss2, memory, death }

class BgmManager {
  static const double defaultVolume = 0.5;

  static const Map<BgmTrack, String> _files = {
    BgmTrack.title: 'bgm_title.mp3',
    BgmTrack.combat: 'bgm_combat.mp3',
    BgmTrack.boss1: 'bgm_boss_1.mp3',
    BgmTrack.boss2: 'bgm_boss_2.mp3',
    BgmTrack.memory: 'bgm_memory.mp3',
    BgmTrack.death: 'bgm_death.mp3',
  };

  BgmTrack? _currentTrack;
  bool _initialized = false;
  int _bossIndex = 0;
  double _volume = defaultVolume;

  double get volume => _volume;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll(_files.values.toList());
      _initialized = true;
    } on Object catch (error) {
      _initialized = true;
      debugPrint('BGM initialize failed: $error');
    }
  }

  Future<void> playTrack(BgmTrack track) async {
    await initialize();
    if (_currentTrack == track) {
      return;
    }

    final file = _files[track];
    if (file == null) {
      return;
    }

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(file, volume: _volume);
      _currentTrack = track;
    } on Object catch (error) {
      debugPrint('BGM play failed ($file): $error');
      _currentTrack = null;
      if (track == BgmTrack.boss1 || track == BgmTrack.boss2) {
        await _playFallbackBossTrack(track);
      }
    }
  }

  Future<void> playBossBgm() async {
    final track = _bossIndex == 0 ? BgmTrack.boss1 : BgmTrack.boss2;
    _bossIndex = 1 - _bossIndex;
    await playTrack(track);
  }

  void resetBossRotation() {
    _bossIndex = 0;
  }

  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
    unawaited(_applyVolume());
  }

  Future<void> pause() async {
    try {
      await FlameAudio.bgm.pause();
    } on Object catch (error) {
      debugPrint('BGM pause failed: $error');
    }
  }

  Future<void> resume() async {
    try {
      await FlameAudio.bgm.resume();
    } on Object catch (error) {
      debugPrint('BGM resume failed: $error');
    }
  }

  Future<void> stop() async {
    try {
      await FlameAudio.bgm.stop();
      _currentTrack = null;
    } on Object catch (error) {
      debugPrint('BGM stop failed: $error');
    }
  }

  void dispose() {
    // FlameAudio.bgm is a process-wide singleton. Disposing it from a game
    // instance can silence BGM after restart, so keep it alive for the app.
  }

  Future<void> _playFallbackBossTrack(BgmTrack failedTrack) async {
    final fallback = failedTrack == BgmTrack.boss1
        ? BgmTrack.boss2
        : BgmTrack.boss1;
    final fallbackFile = _files[fallback];
    if (fallbackFile == null) {
      return;
    }

    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(fallbackFile, volume: _volume);
      _currentTrack = fallback;
    } on Object catch (error) {
      debugPrint('Fallback boss BGM play failed ($fallbackFile): $error');
    }
  }

  Future<void> _applyVolume() async {
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(_volume);
    } on Object catch (error) {
      debugPrint('BGM volume failed: $error');
    }
  }
}
