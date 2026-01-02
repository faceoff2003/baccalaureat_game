import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_models.dart';
import 'dictionary_service.dart';

/// Service de gestion des parties de jeu
class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DictionaryService _dictionary = DictionaryService();
  final Uuid _uuid = const Uuid();

  // Lettres disponibles (sans les rares)
  static const List<String> availableLetters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  // Catégories par défaut
  static List<Category> get defaultCategories => [
    const Category(id: 'prenom.json', name: 'Prénom', isDefault: true),
    const Category(id: 'pays', name: 'Pays', isDefault: true),
    const Category(id: 'ville', name: 'Ville', isDefault: true),
    const Category(id: 'animal', name: 'Animal', isDefault: true),
    const Category(id: 'fruit', name: 'Fruit/Légume', isDefault: true),
    const Category(id: 'objet', name: 'Objet', isDefault: true),
    const Category(id: 'metier', name: 'Métier', isDefault: true),
  ];

  /// Génère un code de room unique (6 caractères)
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Sélectionne une lettre aléatoire non bannie
  String _selectRandomLetter(List<String> bannedLetters, List<String> usedLetters) {
    final available = availableLetters
        .where((l) => !bannedLetters.contains(l) && !usedLetters.contains(l))
        .toList();

    if (available.isEmpty) {
      // Réutiliser les lettres si toutes ont été jouées
      final reusable = availableLetters
          .where((l) => !bannedLetters.contains(l))
          .toList();
      return reusable[Random().nextInt(reusable.length)];
    }

    return available[Random().nextInt(available.length)];
  }

  // ==================== PARTIE SOLO ====================

  /// Crée une nouvelle partie solo
  Future<GameSession> createSoloGame({
    required String odId,
    required String playerName,
    required GameSettings settings,
  }) async {
    final gameId = _uuid.v4();
    final categories = settings.categories.isEmpty
        ? defaultCategories
        : settings.categories;

    final session = GameSession(
      id: gameId,
      hostId: odId,
      isMultiplayer: false,
      settings: settings.copyWith(categories: categories),
      players: [
        Player(id: odId, name: playerName, isReady: true),
      ],
      status: GameStatus.playing,
      createdAt: DateTime.now(),
    );

    return session;
  }

  /// Démarre un nouveau tour (solo)
  GameSession startNewRound(GameSession session, {List<String>? usedLetters}) {
    final letter = _selectRandomLetter(
      session.settings.bannedLetters,
      usedLetters ?? session.rounds.map((r) => r.letter).toList(),
    );

    final newRound = GameRound(
      roundNumber: session.rounds.length + 1,
      letter: letter,
      startedAt: DateTime.now(),
    );

    return GameSession(
      id: session.id,
      hostId: session.hostId,
      isMultiplayer: session.isMultiplayer,
      settings: session.settings,
      players: session.players,
      rounds: [...session.rounds, newRound],
      currentRoundIndex: session.rounds.length,
      status: GameStatus.playing,
      createdAt: session.createdAt,
    );
  }

  /// Valide et enregistre les réponses d'un joueur (solo)
  GameSession submitAnswers({
    required GameSession session,
    required String odId,
    required Map<String, String> answers, // categoryId -> answer
  }) {
    final currentRound = session.currentRound;
    if (currentRound == null) return session;

    final validatedAnswers = <PlayerAnswer>[];

    for (final entry in answers.entries) {
      // final validation = _dictionary.validateAnswer(
      //   answer: entry.value,
      //   letter: currentRound.letter,
      //   minLength: session.settings.minWordLength,
      // );

      final validation = _dictionary.validateAnswer(
        answer: entry.value,
        letter: currentRound.letter,
        categoryId: entry.key,
        minLength: session.settings.minWordLength,
      );

      validatedAnswers.add(PlayerAnswer(
        categoryId: entry.key,
        answer: entry.value,
        isValid: validation.isValid,
        startsWithLetter: validation.startsWithLetter,
        existsInDictionary: validation.existsInDictionary,
        points: validation.isValid
            ? _dictionary.calculatePoints(
          answer: entry.value,
          isValid: true,
          isUnique: true, // Toujours unique en solo
        )
            : 0,
      ));
    }

    // Mettre à jour le round avec les réponses
    final updatedRounds = session.rounds.map((round) {
      if (round.roundNumber == currentRound.roundNumber) {
        return GameRound(
          roundNumber: round.roundNumber,
          letter: round.letter,
          playerAnswers: {
            ...round.playerAnswers,
            odId: validatedAnswers,
          },
          startedAt: round.startedAt,
          endedAt: DateTime.now(),
        );
      }
      return round;
    }).toList();

    // Calculer le score total
    final totalRoundPoints = validatedAnswers.fold<int>(
      0, (sum, a) => sum + a.points,
    );

    final updatedPlayers = session.players.map((p) {
      if (p.id == odId) {
        return p.copyWith(totalScore: p.totalScore + totalRoundPoints);
      }
      return p;
    }).toList();

    return GameSession(
      id: session.id,
      hostId: session.hostId,
      isMultiplayer: session.isMultiplayer,
      settings: session.settings,
      players: updatedPlayers,
      rounds: updatedRounds,
      currentRoundIndex: session.currentRoundIndex,
      status: GameStatus.roundEnd,
      createdAt: session.createdAt,
    );
  }

  // ==================== PARTIE MULTIJOUEUR ====================

  /// Crée une nouvelle room multijoueur
  Future<GameSession> createMultiplayerRoom({
    required String odId,
    required String playerName,
    required GameSettings settings,
  }) async {
    final gameId = _uuid.v4();
    final roomCode = _generateRoomCode();
    final categories = settings.categories.isEmpty
        ? defaultCategories
        : settings.categories;

    final session = GameSession(
      id: gameId,
      hostId: odId,
      roomCode: roomCode,
      isMultiplayer: true,
      settings: settings.copyWith(categories: categories),
      players: [
        Player(id: odId, name: playerName, isReady: false),
      ],
      status: GameStatus.waiting,
      createdAt: DateTime.now(),
    );

    // Sauvegarder dans Firestore
    await _firestore.collection('games').doc(gameId).set(session.toJson());

    return session;
  }

  /// Rejoindre une room avec un code
  Future<GameSession?> joinRoom({
    required String roomCode,
    required String odId,
    required String playerName,
  }) async {
    // Rechercher la room par code
    final query = await _firestore
        .collection('games')
        .where('roomCode', isEqualTo: roomCode.toUpperCase())
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final session = GameSession.fromJson(doc.data());

    // Vérifier le nombre de joueurs
    if (session.players.length >= 10) return null;

    // Vérifier si déjà dans la partie
    if (session.players.any((p) => p.id == odId)) {
      return session;
    }

    // Ajouter le joueur
    final newPlayer = Player(id: odId, name: playerName);
    final updatedPlayers = [...session.players, newPlayer];

    await _firestore.collection('games').doc(session.id).update({
      'players': updatedPlayers.map((p) => p.toJson()).toList(),
    });

    return GameSession(
      id: session.id,
      hostId: session.hostId,
      roomCode: session.roomCode,
      isMultiplayer: true,
      settings: session.settings,
      players: updatedPlayers,
      rounds: session.rounds,
      currentRoundIndex: session.currentRoundIndex,
      status: session.status,
      createdAt: session.createdAt,
    );
  }

  /// Stream pour écouter les changements d'une partie
  Stream<GameSession?> watchGame(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return GameSession.fromJson(doc.data()!);
    });
  }

  /// Marquer un joueur comme prêt
  Future<void> setPlayerReady({
    required String gameId,
    required String odId,
    required bool isReady,
  }) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final updatedPlayers = session.players.map((p) {
      if (p.id == odId) {
        return p.copyWith(isReady: isReady);
      }
      return p;
    }).toList();

    await _firestore.collection('games').doc(gameId).update({
      'players': updatedPlayers.map((p) => p.toJson()).toList(),
    });
  }

  /// Démarrer la partie multijoueur (host only)
  Future<void> startMultiplayerGame(String gameId) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);

    // Créer le premier round
    final letter = _selectRandomLetter(session.settings.bannedLetters, []);
    final newRound = GameRound(
      roundNumber: 1,
      letter: letter,
      startedAt: DateTime.now(),
    );

    await _firestore.collection('games').doc(gameId).update({
      'status': 'playing',
      'rounds': [newRound.toJson()],
      'currentRoundIndex': 0,
    });
  }

  /// Soumettre les réponses en multijoueur
  Future<void> submitMultiplayerAnswers({
    required String gameId,
    required String odId,
    required Map<String, String> answers,
  }) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);
    final currentRound = session.currentRound;
    if (currentRound == null) return;

    final validatedAnswers = <PlayerAnswer>[];

    for (final entry in answers.entries) {
      // final validation = _dictionary.validateAnswer(
      //   answer: entry.value,
      //   letter: currentRound.letter,
      //   minLength: session.settings.minWordLength,
      // );

      final validation = _dictionary.validateAnswer(
        answer: entry.value,
        letter: currentRound.letter,
        categoryId: entry.key,
        minLength: session.settings.minWordLength,
      );

      validatedAnswers.add(PlayerAnswer(
        categoryId: entry.key,
        answer: entry.value,
        isValid: validation.isValid,
        startsWithLetter: validation.startsWithLetter,
        existsInDictionary: validation.existsInDictionary,
        points: 0, // Calculé après
      ));
    }

    // Mettre à jour Firestore avec les réponses
    final updatedAnswers = Map<String, dynamic>.from(
      currentRound.playerAnswers.map(
            (k, v) => MapEntry(k, v.map((a) => a.toJson()).toList()),
      ),
    );
    updatedAnswers[odId] = validatedAnswers.map((a) => a.toJson()).toList();

    await _firestore.collection('games').doc(gameId).update({
      'rounds.${session.currentRoundIndex}.playerAnswers': updatedAnswers,
    });
  }

  /// Calcule les scores finaux d'un round (vérifie les doublons)
  Map<String, int> calculateRoundScores(GameRound round) {
    final scores = <String, int>{};

    // Collecter toutes les réponses par catégorie
    final answersByCategory = <String, Map<String, List<String>>>{};

    for (final entry in round.playerAnswers.entries) {
      final odId = entry.key;
      for (final answer in entry.value) {
        answersByCategory.putIfAbsent(answer.categoryId, () => {});
        answersByCategory[answer.categoryId]!.putIfAbsent(
          answer.answer.toLowerCase().trim(),
              () => [],
        );
        answersByCategory[answer.categoryId]![answer.answer.toLowerCase().trim()]!
            .add(odId);
      }
    }

    // Calculer les points
    for (final entry in round.playerAnswers.entries) {
      final odId = entry.key;
      int playerScore = 0;

      for (final answer in entry.value) {
        if (!answer.isValid) continue;

        final normalizedAnswer = answer.answer.toLowerCase().trim();
        final playersWithSameAnswer = answersByCategory[answer.categoryId]?[normalizedAnswer] ?? [];
        final isUnique = playersWithSameAnswer.length == 1;

        playerScore += _dictionary.calculatePoints(
          answer: answer.answer,
          isValid: true,
          isUnique: isUnique,
        );
      }

      scores[odId] = playerScore;
    }

    return scores;
  }

  /// Quitter une partie
  Future<void> leaveGame({
    required String gameId,
    required String odId,
  }) async {
    final doc = await _firestore.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final session = GameSession.fromJson(doc.data()!);

    // Si c'est l'hôte et la partie n'a pas commencé, supprimer la room
    if (session.hostId == odId && session.status == GameStatus.waiting) {
      await _firestore.collection('games').doc(gameId).delete();
      return;
    }

    // Sinon, retirer le joueur
    final updatedPlayers = session.players.where((p) => p.id != odId).toList();

    if (updatedPlayers.isEmpty) {
      await _firestore.collection('games').doc(gameId).delete();
    } else {
      await _firestore.collection('games').doc(gameId).update({
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
      });
    }
  }

  // ==================== HISTORIQUE & LEADERBOARD ====================

  /// Sauvegarder une partie dans l'historique
  Future<void> saveGameHistory({
    required String odId,
    required GameSession session,
    required int finalScore,
    required int rank,
  }) async {
    final history = GameHistory(
      id: _uuid.v4(),
      odId: odId,
      isMultiplayer: session.isMultiplayer,
      playerCount: session.players.length,
      roundsPlayed: session.rounds.length,
      finalScore: finalScore,
      rank: rank,
      playedAt: DateTime.now(),
      categories: session.settings.categories.map((c) => c.name).toList(),
    );

    await _firestore
        .collection('users')
        .doc(odId)
        .collection('history')
        .doc(history.id)
        .set(history.toJson());

    // Mettre à jour les statistiques utilisateur
    await _firestore.collection('users').doc(odId).update({
      'totalPoints': FieldValue.increment(finalScore),
      'gamesPlayed': FieldValue.increment(1),
      if (rank == 1) 'gamesWon': FieldValue.increment(1),
    });
  }

  /// Récupérer l'historique d'un joueur
  Future<List<GameHistory>> getPlayerHistory(String odId, {int limit = 20}) async {
    final query = await _firestore
        .collection('users')
        .doc(odId)
        .collection('history')
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => GameHistory.fromJson(doc.data()))
        .toList();
  }

  /// Récupérer le leaderboard global
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    final query = await _firestore
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      final gamesPlayed = data['gamesPlayed'] as int? ?? 0;
      final gamesWon = data['gamesWon'] as int? ?? 0;

      return LeaderboardEntry(
        odId: doc.id,
        playerName: data['displayName'] as String? ?? 'Anonyme',
        totalPoints: data['totalPoints'] as int? ?? 0,
        gamesPlayed: gamesPlayed,
        gamesWon: gamesWon,
        winRate: gamesPlayed > 0 ? gamesWon / gamesPlayed : 0,
      );
    }).toList();
  }
}
