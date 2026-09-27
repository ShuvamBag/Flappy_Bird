import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Keeps one low-latency mixer ready for music and game sound effects.
class GameAudio {
  GameAudio() {
    _ready = _initialize();
  }

  static const _musicVolume = 0.2;
  static const _flapVolume = 1.0;

  final SoLoud _engine = SoLoud.instance;
  late final Future<void> _ready;

  AudioSource? _flap;
  AudioSource? _gameOver;
  AudioSource? _music;
  SoundHandle? _musicHandle;
  bool _initialized = false;
  bool _disposed = false;

  Future<void> _initialize() async {
    try {
      // 512 frames cuts the mixer buffer to about 12 ms at 44.1 kHz.
      await _engine.init(bufferSize: 512, lowLatency: true);
      _initialized = true;
      _flap = await _engine.loadAsset(
        'assets/sounds/flap.mp3',
        mode: LoadMode.memory,
      );
      _gameOver = await _engine.loadAsset(
        'assets/sounds/negative_beeps-6008.mp3',
        mode: LoadMode.memory,
      );
      _music = await _engine.loadAsset(
        'assets/sounds/gentle_background.wav',
        mode: LoadMode.memory,
      );
    } catch (_) {
      // Audio is optional; keep the game playable if a browser blocks it.
      await _deinitialize();
    }
  }

  /// Starts the background loop once and plays the preloaded flap immediately.
  /// Call this directly from the tap handler so mobile browsers see the gesture.
  void playTap() {
    if (!_initialized || _disposed || _flap == null || _music == null) return;

    try {
      final currentMusic = _musicHandle;
      if (currentMusic == null || !_engine.getIsValidVoiceHandle(currentMusic)) {
        _musicHandle = _engine.play(
          _music!,
          volume: _musicVolume,
          looping: true,
        );
      }
      _engine.play(_flap!, volume: _flapVolume);
    } catch (_) {
      // Audio errors must not interrupt the game loop.
    }
  }

  /// Fades out the music and plays the game-over cue on the same mixer.
  void playGameOver() {
    if (!_initialized || _disposed || _gameOver == null) return;
    _fadeOutMusic();
    try {
      _engine.play(_gameOver!, volume: 1.0);
    } catch (_) {
      // Audio errors must not interrupt the game loop.
    }
  }

  void _fadeOutMusic() {
    final handle = _musicHandle;
    _musicHandle = null;
    if (handle == null || !_engine.getIsValidVoiceHandle(handle)) return;

    try {
      _engine.fadeVolume(handle, 0, const Duration(milliseconds: 300));
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 320), () async {
          if (_initialized && _engine.getIsValidVoiceHandle(handle)) {
            await _engine.stop(handle);
          }
        }),
      );
    } catch (_) {
      unawaited(_stopHandle(handle));
    }
  }

  Future<void> _stopHandle(SoundHandle handle) async {
    try {
      if (_initialized && _engine.getIsValidVoiceHandle(handle)) {
        await _engine.stop(handle);
      }
    } catch (_) {
      // Ignore an already stopped voice.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ready;
    await _deinitialize();
  }

  Future<void> _deinitialize() async {
    if (!_initialized) return;
    try {
      _engine.deinit();
    } catch (_) {
      // The engine may already have been shut down by the browser.
    } finally {
      _initialized = false;
      _musicHandle = null;
      _flap = null;
      _gameOver = null;
      _music = null;
    }
  }
}
