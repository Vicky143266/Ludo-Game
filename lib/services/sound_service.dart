import 'package:audioplayers/audioplayers.dart';

enum SoundEffect {
  diceRoll,
  diceResult,
  diceSix,
  tokenMove,
  tokenEntry,
  tokenCapture,
  tokenFinish,
  victory,
  invalidMove,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool soundEnabled = true;

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  bool _musicEnabled = true;
  bool get musicEnabled => _musicEnabled;

  static const Map<SoundEffect, String> _assetMap = {
    SoundEffect.diceRoll: 'audio/dice_roll.mp3',
    SoundEffect.diceResult: 'audio/dice_result.mp3',
    SoundEffect.diceSix: 'audio/dice_six.mp3',
    SoundEffect.tokenMove: 'audio/token_move.mp3',
    SoundEffect.tokenEntry: 'audio/token_entry.mp3',
    SoundEffect.tokenCapture: 'audio/token_capture.mp3',
    SoundEffect.tokenFinish: 'audio/token_finish.mp3',
    SoundEffect.victory: 'audio/victory.mp3',
    SoundEffect.invalidMove: 'audio/invalid_move.mp3',
  };

  /// Play a one-shot sound effect.
  Future<void> play(SoundEffect effect) async {
    if (!soundEnabled) return;
    final asset = _assetMap[effect];
    if (asset == null) return;
    try {
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Gracefully handle missing audio assets
    }
  }

  /// Start looping background music.
  /// Call this once when the game screen is ready.
  /// Provide a path like 'audio/bg_music.mp3' relative to assets/.
  Future<void> startMusic(String assetPath) async {
    if (!_musicEnabled) return;
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.setVolume(0.4); // softer than SFX
      await _bgPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Gracefully handle missing music file
    }
  }

  /// Stop background music immediately.
  Future<void> stopMusic() async {
    try {
      await _bgPlayer.stop();
    } catch (_) {}
  }

  /// Toggle background music on/off.
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await stopMusic();
    }
    // Resuming music is handled by the caller via startMusic()
  }

  void dispose() {
    _player.dispose();
    _bgPlayer.dispose();
  }
}
