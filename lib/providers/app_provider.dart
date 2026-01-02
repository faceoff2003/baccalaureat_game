import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_models.dart';
import '../services/auth_service.dart';
import '../services/game_service.dart';
import '../services/dictionary_service.dart';
import '../services/audio_service.dart';
import '../services/vote_service.dart';

/// Provider principal pour la gestion d'état de l'application
class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GameService _gameService = GameService();
  final VoteService _voteService = VoteService();
  final DictionaryService _dictionaryService = DictionaryService();
  final AudioService _audioService = AudioService();

  // État de l'app
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<VoteSession> _pendingVotes = [];

  // Thème
  ThemeMode _themeMode = ThemeMode.dark;

  // Utilisateur
  String? _odId;
  String? _displayName;
  String? _email;

  // Partie en cours
  GameSession? _currentGame;
  StreamSubscription? _gameSubscription;

  // Timer
  Timer? _gameTimer;
  int _remainingTime = 0;

  // Réponses en cours de saisie
  Map<String, String> _currentAnswers = {};

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isLoggedIn => _odId != null;
  String? get odId => _odId;
  String? get displayName => _displayName;
  String? get email => _email;
  GameSession? get currentGame => _currentGame;
  int get remainingTime => _remainingTime;
  Map<String, String> get currentAnswers => _currentAnswers;
  AudioService get audioService => _audioService;
  GameService get gameService => _gameService;
  List<VoteSession> get pendingVotes => _pendingVotes;
  VoteService get voteService => _voteService;

  /// Initialise l'application
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      // await _dictionaryService.loadDictionary();
      await _dictionaryService.loadDictionaries();
      await _audioService.init();

      await _voteService.loadCustomWords();

      final user = _authService.currentUser;
      if (user != null) {
        _odId = user.uid;
        _displayName = user.displayName;
        _email = user.email;
      }

      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Change le thème
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
    notifyListeners();
  }

  // ==================== AUTHENTIFICATION ====================

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.isSuccess && result.user != null) {
        _odId = result.user!.uid;
        _displayName = displayName;
        _email = email;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners();
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (result.isSuccess && result.user != null) {
        _odId = result.user!.uid;
        _displayName = result.user!.displayName;
        _email = result.user!.email;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners();
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInAnonymously();

      if (result.isSuccess && result.user != null) {
        _odId = result.user!.uid;
        _displayName = result.user!.displayName;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners();
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();

      if (result.isSuccess && result.user != null) {
        _odId = result.user!.uid;
        _displayName = result.user!.displayName;
        _email = result.user!.email;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorMessage;
        notifyListeners();
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _odId = null;
    _displayName = null;
    _email = null;
    _currentGame = null;
    _gameSubscription?.cancel();
    _gameTimer?.cancel();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.resetPassword(email);
      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }
      notifyListeners();
      return result.isSuccess;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== JEU SOLO ====================

  Future<void> startSoloGame(GameSettings settings) async {
    if (_odId == null || _displayName == null) return;

    _setLoading(true);
    _clearError();

    try {
      _currentGame = await _gameService.createSoloGame(
        odId: _odId!,
        playerName: _displayName!,
        settings: settings,
      );

      _currentGame = _gameService.startNewRound(_currentGame!);
      _startTimer();
      await _audioService.playSfx(SoundEffect.roundStart);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void updateAnswer(String categoryId, String answer) {
    _currentAnswers[categoryId] = answer;
    notifyListeners();
  }

  Future<void> submitSoloAnswers() async {
    if (_currentGame == null || _odId == null) return;

    _gameTimer?.cancel();
    await _audioService.playSfx(SoundEffect.roundEnd);

    _currentGame = _gameService.submitAnswers(
      session: _currentGame!,
      odId: _odId!,
      answers: _currentAnswers,
    );

    _currentAnswers = {};
    notifyListeners();
  }

  Future<void> nextRound() async {
    if (_currentGame == null) return;

    _currentGame = _gameService.startNewRound(_currentGame!);
    _startTimer();
    await _audioService.playSfx(SoundEffect.roundStart);
    notifyListeners();
  }

  Future<void> endGame() async {
    _gameTimer?.cancel();

    if (_currentGame != null && _odId != null) {
      final player = _currentGame!.players.firstWhere((p) => p.id == _odId);

      await _gameService.saveGameHistory(
        odId: _odId!,
        session: _currentGame!,
        finalScore: player.totalScore,
        rank: 1,
      );

      await _audioService.playSfx(SoundEffect.victory);
    }

    _currentGame = null;
    _currentAnswers = {};
    notifyListeners();
  }

  // ==================== JEU MULTIJOUEUR ====================

  Future<String?> createMultiplayerRoom(GameSettings settings) async {
    if (_odId == null || _displayName == null) return null;

    _setLoading(true);
    _clearError();

    try {
      _currentGame = await _gameService.createMultiplayerRoom(
        odId: _odId!,
        playerName: _displayName!,
        settings: settings,
      );

      _subscribeToGame(_currentGame!.id);
      notifyListeners();
      return _currentGame?.roomCode;
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> joinRoom(String roomCode) async {
    if (_odId == null || _displayName == null) return false;

    _setLoading(true);
    _clearError();

    try {
      _currentGame = await _gameService.joinRoom(
        roomCode: roomCode,
        odId: _odId!,
        playerName: _displayName!,
      );

      if (_currentGame != null) {
        _subscribeToGame(_currentGame!.id);
        await _audioService.playSfx(SoundEffect.playerJoin);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Room introuvable ou pleine';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _subscribeToGame(String gameId) {
    _gameSubscription?.cancel();
    _gameSubscription = _gameService.watchGame(gameId).listen((session) {
      if (session != null) {
        final previousStatus = _currentGame?.status;
        _currentGame = session;

        if (previousStatus != session.status) {
          _handleStatusChange(previousStatus, session.status);
        }

        notifyListeners();
      }
    });
  }

  void _handleStatusChange(GameStatus? previous, GameStatus current) async {
    switch (current) {
      case GameStatus.playing:
        if (previous == GameStatus.waiting || previous == GameStatus.roundEnd) {
          _startTimer();
          await _audioService.playSfx(SoundEffect.roundStart);
        }
        break;
      case GameStatus.roundEnd:
        _gameTimer?.cancel();
        await _audioService.playSfx(SoundEffect.roundEnd);
        break;
      case GameStatus.finished:
        _gameTimer?.cancel();
        await _audioService.playSfx(SoundEffect.victory);
        break;
      default:
        break;
    }
  }

  Future<void> setReady(bool isReady) async {
    if (_currentGame == null || _odId == null) return;

    await _gameService.setPlayerReady(
      gameId: _currentGame!.id,
      odId: _odId!,
      isReady: isReady,
    );

    if (isReady) {
      await _audioService.playSfx(SoundEffect.playerReady);
    }
  }

  Future<void> startMultiplayerGame() async {
    if (_currentGame == null || _currentGame!.hostId != _odId) return;
    await _gameService.startMultiplayerGame(_currentGame!.id);
    await _audioService.playSfx(SoundEffect.gameStart);
  }

  Future<void> submitMultiplayerAnswers() async {
    if (_currentGame == null || _odId == null) return;

    await _gameService.submitMultiplayerAnswers(
      gameId: _currentGame!.id,
      odId: _odId!,
      answers: _currentAnswers,
    );

    _currentAnswers = {};
    notifyListeners();
  }

  Future<void> leaveGame() async {
    if (_currentGame == null || _odId == null) return;

    _gameTimer?.cancel();
    _gameSubscription?.cancel();

    if (_currentGame!.isMultiplayer) {
      await _gameService.leaveGame(
        gameId: _currentGame!.id,
        odId: _odId!,
      );
    }

    _currentGame = null;
    _currentAnswers = {};
    notifyListeners();
  }


  /// ====================SYSTÈME DE VOTE==========================

  /// Collecte les mots non reconnus pour le vote (multijoueur)
  Future<List<VoteSession>> collectWordsForVote({
    required String gameId,
    required String odId,
    required String odName,
    required Map<String, String> answers,
    required String letter,
    required List<Category> categories,
  }) async {
    final List<VoteSession> votes = [];

    for (final category in categories) {
      final answer = answers[category.id]?.trim() ?? '';

      if (answer.isEmpty) continue;

      // Vérifier si le mot existe dans le dictionnaire
      final validation = _dictionaryService.validateAnswer(
        answer: answer,
        letter: letter,
        categoryId: category.id,
        minLength: 2,
      );

      // Si le mot nécessite un vote
      if (validation.needsVote) {
        final voteSession = await _voteService.createVoteSession(
          gameId: gameId,
          odId: odId,
          odName: odName,
          word: answer,
          categoryId: category.id,
          categoryName: category.name,
          letter: letter,
        );

        if (voteSession != null) {
          votes.add(voteSession);
        }
      }
    }

    _pendingVotes = votes;
    notifyListeners();

    return votes;
  }

  /// Récupère les votes en attente pour une partie
  Future<List<VoteSession>> getPendingVotes(String gameId) async {
    _pendingVotes = await _voteService.getPendingVotes(gameId);
    notifyListeners();
    return _pendingVotes;
  }

  /// Charge les mots personnalisés depuis Firestore
  Future<void> loadCustomWords() async {
    await _voteService.loadCustomWords();
  }

  // ==================== TIMER ====================

  /// Démarre le timer du round
  void _startTimer() {
    // Annuler tout timer existant
    _gameTimer?.cancel();

    // Initialiser le temps
    _remainingTime = _currentGame?.settings.timePerLetter ?? 60;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;

        // Son warning à 10 secondes
        if (_remainingTime == 10) {
          _audioService.playSfx(SoundEffect.timerWarning);
        }

        notifyListeners();
      }

      // Temps écoulé
      if (_remainingTime <= 0) {
        timer.cancel();
        _gameTimer = null;

        _audioService.playSfx(SoundEffect.timeUp);

        // Soumettre automatiquement les réponses
        if (_currentGame != null) {
          if (_currentGame!.isMultiplayer) {
            submitMultiplayerAnswers();
          } else {
            submitSoloAnswers();
          }
        }
      }
    });
  }

  // void _startTimer() {
  //   _gameTimer?.cancel();
  //   _remainingTime = _currentGame?.settings.timePerLetter ?? 60;
  //
  //   _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     _remainingTime--;
  //
  //     if (_remainingTime == 10) {
  //       _audioService.playSfx(SoundEffect.timerWarning);
  //     }
  //
  //     if (_remainingTime <= 0) {
  //       timer.cancel();
  //       _audioService.playSfx(SoundEffect.timeUp);
  //
  //       if (_currentGame?.isMultiplayer == true) {
  //         submitMultiplayerAnswers();
  //       } else {
  //         submitSoloAnswers();
  //       }
  //     }
  //
  //     notifyListeners();
  //   });
  // }

  // ==================== HISTORIQUE & LEADERBOARD ====================

  Future<List<GameHistory>> getHistory() async {
    if (_odId == null) return [];
    return _gameService.getPlayerHistory(_odId!);
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    return _gameService.getLeaderboard();
  }

  // ==================== UTILITAIRES ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _gameSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
