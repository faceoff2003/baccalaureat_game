import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des sons du jeu
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 0.7;
  double _musicVolume = 0.5;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;

  /// Initialise le service audio
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    _soundVolume = prefs.getDouble('soundVolume') ?? 0.7;
    _musicVolume = prefs.getDouble('musicVolume') ?? 0.5;

    await _sfxPlayer.setVolume(_soundVolume);
    await _musicPlayer.setVolume(_musicVolume);
  }

  /// Active/désactive les effets sonores
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
  }

  /// Active/désactive la musique
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', enabled);

    if (!enabled) {
      await _musicPlayer.stop();
    }
  }

  /// Définit le volume des effets sonores
  Future<void> setSoundVolume(double volume) async {
    _soundVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_soundVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('soundVolume', _soundVolume);
  }

  /// Définit le volume de la musique
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_musicVolume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', _musicVolume);
  }

  /// Joue un effet sonore
  Future<void> playSfx(SoundEffect effect) async {
    if (!_soundEnabled) return;

    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(effect.assetPath));
    } catch (e) {
      print('Erreur lecture son: $e');
    }
  }

  /// Joue la musique de fond
  Future<void> playBackgroundMusic() async {
    if (!_musicEnabled) return;

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('sounds/background_music.mp3'));
    } catch (e) {
      print('Erreur lecture musique: $e');
    }
  }

  /// Arrête la musique de fond
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  /// Pause la musique
  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  /// Reprend la musique
  Future<void> resumeBackgroundMusic() async {
    if (_musicEnabled) {
      await _musicPlayer.resume();
    }
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
  }
}

/// Énumération des effets sonores disponibles
enum SoundEffect {
  buttonClick('sounds/click.mp3'),
  letterSpin('sounds/spin.mp3'),
  letterStop('sounds/stop.mp3'),
  timerTick('sounds/tick.mp3'),
  timerWarning('sounds/warning.mp3'),
  timeUp('sounds/time_up.mp3'),
  correctAnswer('sounds/correct.mp3'),
  wrongAnswer('sounds/wrong.mp3'),
  roundStart('sounds/round_start.mp3'),
  roundEnd('sounds/round_end.mp3'),
  victory('sounds/victory.mp3'),
  playerJoin('sounds/join.mp3'),
  playerReady('sounds/ready.mp3'),
  gameStart('sounds/game_start.mp3');

  final String assetPath;
  const SoundEffect(this.assetPath);
}
