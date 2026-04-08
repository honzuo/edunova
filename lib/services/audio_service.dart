import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final Map<String, AudioPlayer> _players = {};
  final Map<String, double> _volumes = {};

  static const _fadeDuration = Duration(milliseconds: 800);
  static const _fadeSteps = 20;

  static const Map<String, String> soundAssets = {
    'rain': 'assets/audio/rain.mp3',
    'cafe': 'assets/audio/cafe.mp3',
    'fire': 'assets/audio/fire.mp3',
    'forest': 'assets/audio/forest.mp3',
    'ocean': 'assets/audio/ocean.mp3',
    'library': 'assets/audio/library.mp3',
  };

  Set<String> get activeSounds =>
      _players.entries.where((e) => e.value.playing).map((e) => e.key).toSet();

  double getVolume(String id) => _volumes[id] ?? 0.5;

  bool isPlaying(String id) => _players[id]?.playing ?? false;

  Future<void> play(String id, {double volume = 0.5}) async {
    // Already playing
    if (_players.containsKey(id) && _players[id]!.playing) return;

    // Cleanup old player if exists
    await _cleanup(id);

    final player = AudioPlayer();
    _players[id] = player;
    _volumes[id] = volume;

    try {
      await player.setAsset(soundAssets[id]!);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0);
      // Don't await play() - it blocks until playback finishes
      unawaited(player.play());
      await _fade(player, 0, volume);
    } catch (e) {
      debugPrint('AudioService play error ($id): $e');
      await _cleanup(id);
    }
  }

  Future<void> stop(String id) async {
    final player = _players[id];
    if (player == null || !player.playing) {
      await _cleanup(id);
      return;
    }
    try {
      await _fade(player, player.volume, 0);
    } catch (_) {}
    await _cleanup(id);
  }

  Future<void> toggle(String id, {double volume = 0.5}) async {
    if (isPlaying(id)) {
      await stop(id);
    } else {
      await play(id, volume: _volumes[id] ?? volume);
    }
  }

  Future<void> setVolume(String id, double vol) async {
    _volumes[id] = vol.clamp(0.0, 1.0);
    final player = _players[id];
    if (player != null && player.playing) {
      await player.setVolume(_volumes[id]!);
    }
  }

  Future<void> stopAll() async {
    final ids = _players.keys.toList();
    await Future.wait(ids.map(stop));
  }

  Future<void> _fade(AudioPlayer player, double from, double to) async {
    final step = _fadeDuration ~/ _fadeSteps;
    final delta = (to - from) / _fadeSteps;
    for (int i = 1; i <= _fadeSteps; i++) {
      if (!player.playing && to > 0) return;
      await player.setVolume((from + delta * i).clamp(0.0, 1.0));
      await Future.delayed(step);
    }
  }

  Future<void> _cleanup(String id) async {
    final player = _players.remove(id);
    if (player != null) {
      try {
        await player.stop();
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      try { await p.stop(); await p.dispose(); } catch (_) {}
    }
    _players.clear();
    _volumes.clear();
  }
}
