


/// Représente une catégorie de jeu (ex: Prénom, Pays, etc.)
class Category {
  final String id;
  final String name;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isDefault': isDefault,
  };

  List<Object?> get props => [id, name, isDefault];
}

/// Configuration d'une partie
class GameSettings {
  final int timePerLetter; // en secondes
  final List<String> bannedLetters;
  final List<Category> categories;
  final int minWordLength;
  final bool soundEnabled;
  final bool animationsEnabled;
  final bool easyMode;

  const GameSettings({
    this.timePerLetter = 60,
    this.bannedLetters = const [],
    this.categories = const [],
    this.minWordLength = 2,
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.easyMode = false,
  });

  GameSettings copyWith({
    int? timePerLetter,
    List<String>? bannedLetters,
    List<Category>? categories,
    int? minWordLength,
    bool? soundEnabled,
    bool? animationsEnabled,
  }) {
    return GameSettings(
      timePerLetter: timePerLetter ?? this.timePerLetter,
      bannedLetters: bannedLetters ?? this.bannedLetters,
      categories: categories ?? this.categories,
      minWordLength: minWordLength ?? this.minWordLength,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      easyMode: easyMode ?? this.easyMode,
    );
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      timePerLetter: json['timePerLetter'] as int? ?? 60,
      bannedLetters: List<String>.from(json['bannedLetters'] ?? []),
      categories: (json['categories'] as List?)
          ?.map((c) => Category.fromJson(c))
          .toList() ?? [],
      minWordLength: json['minWordLength'] as int? ?? 2,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      animationsEnabled: json['animationsEnabled'] as bool? ?? true,
      easyMode: json['easyMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'timePerLetter': timePerLetter,
    'bannedLetters': bannedLetters,
    'categories': categories.map((c) => c.toJson()).toList(),
    'minWordLength': minWordLength,
    'soundEnabled': soundEnabled,
    'animationsEnabled': animationsEnabled,
    'easyMode': easyMode,
  };

  List<Object?> get props => [
    timePerLetter,
    bannedLetters,
    categories,
    minWordLength,
    soundEnabled,
    animationsEnabled,
    easyMode,
  ];
}

/// Réponse d'un joueur pour une catégorie
class PlayerAnswer{
  final String categoryId;
  final String answer;
  final bool isValid;
  final bool startsWithLetter;
  final bool existsInDictionary;
  final int points;

  const PlayerAnswer({
    required this.categoryId,
    required this.answer,
    this.isValid = false,
    this.startsWithLetter = false,
    this.existsInDictionary = false,
    this.points = 0,
  });

  PlayerAnswer copyWith({
    String? categoryId,
    String? answer,
    bool? isValid,
    bool? startsWithLetter,
    bool? existsInDictionary,
    int? points,
  }) {
    return PlayerAnswer(
      categoryId: categoryId ?? this.categoryId,
      answer: answer ?? this.answer,
      isValid: isValid ?? this.isValid,
      startsWithLetter: startsWithLetter ?? this.startsWithLetter,
      existsInDictionary: existsInDictionary ?? this.existsInDictionary,
      points: points ?? this.points,
    );
  }

  factory PlayerAnswer.fromJson(Map<String, dynamic> json) {
    return PlayerAnswer(
      categoryId: json['categoryId'] as String,
      answer: json['answer'] as String,
      isValid: json['isValid'] as bool? ?? false,
      startsWithLetter: json['startsWithLetter'] as bool? ?? false,
      existsInDictionary: json['existsInDictionary'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'answer': answer,
    'isValid': isValid,
    'startsWithLetter': startsWithLetter,
    'existsInDictionary': existsInDictionary,
    'points': points,
  };

  List<Object?> get props => [
    categoryId,
    answer,
    isValid,
    startsWithLetter,
    existsInDictionary,
    points,
  ];
}

/// Tour de jeu (une lettre)
class GameRound{
  final int roundNumber;
  final String letter;
  final Map<String, List<PlayerAnswer>> playerAnswers; // playerId -> answers
  final DateTime startedAt;
  final DateTime? endedAt;

  const GameRound({
    required this.roundNumber,
    required this.letter,
    this.playerAnswers = const {},
    required this.startedAt,
    this.endedAt,
  });

  factory GameRound.fromJson(Map<String, dynamic> json) {
    final answersMap = <String, List<PlayerAnswer>>{};
    if (json['playerAnswers'] != null) {
      (json['playerAnswers'] as Map<String, dynamic>).forEach((key, value) {
        answersMap[key] = (value as List)
            .map((a) => PlayerAnswer.fromJson(a))
            .toList();
      });
    }

    return GameRound(
      roundNumber: json['roundNumber'] as int,
      letter: json['letter'] as String,
      playerAnswers: answersMap,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'roundNumber': roundNumber,
    'letter': letter,
    'playerAnswers': playerAnswers.map(
          (key, value) => MapEntry(key, value.map((a) => a.toJson()).toList()),
    ),
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  List<Object?> get props => [roundNumber, letter, playerAnswers, startedAt, endedAt];
}

/// État d'une partie
enum GameStatus {
  waiting,    // En attente de joueurs
  starting,   // Démarrage imminent
  playing,    // En cours
  roundEnd,   // Fin de tour (affichage scores)
  finished,   // Terminée
}

/// Partie de jeu
class GameSession{
  final String id;
  final String hostId;
  final String? roomCode;
  final bool isMultiplayer;
  final GameSettings settings;
  final List<Player> players;
  final List<GameRound> rounds;
  final int currentRoundIndex;
  final GameStatus status;
  final DateTime createdAt;
  final DateTime? finishedAt;

  const GameSession({
    required this.id,
    required this.hostId,
    this.roomCode,
    required this.isMultiplayer,
    required this.settings,
    this.players = const [],
    this.rounds = const [],
    this.currentRoundIndex = 0,
    this.status = GameStatus.waiting,
    required this.createdAt,
    this.finishedAt,
  });

  GameRound? get currentRound =>
      currentRoundIndex < rounds.length ? rounds[currentRoundIndex] : null;

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      hostId: json['hostId'] as String,
      roomCode: json['roomCode'] as String?,
      isMultiplayer: json['isMultiplayer'] as bool,
      settings: GameSettings.fromJson(json['settings']),
      players: (json['players'] as List?)
          ?.map((p) => Player.fromJson(p))
          .toList() ?? [],
      rounds: (json['rounds'] as List?)
          ?.map((r) => GameRound.fromJson(r))
          .toList() ?? [],
      currentRoundIndex: json['currentRoundIndex'] as int? ?? 0,
      status: GameStatus.values.firstWhere(
            (s) => s.name == json['status'],
        orElse: () => GameStatus.waiting,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'hostId': hostId,
    'roomCode': roomCode,
    'isMultiplayer': isMultiplayer,
    'settings': settings.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'currentRoundIndex': currentRoundIndex,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
  };

  // List<Object?> get props => [
  //   id, hostId, roomCode, isMultiplayer, settings,
  //   players, rounds, currentRoundIndex, status, createdAt, finishedAt,
  // ];
}

/// Joueur
class Player{
  final String id;
  final String name;
  final String? avatarUrl;
  final int totalScore;
  final bool isReady;
  final bool isOnline;

  const Player({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.totalScore = 0,
    this.isReady = false,
    this.isOnline = true,
  });

  Player copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? totalScore,
    bool? isReady,
    bool? isOnline,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalScore: totalScore ?? this.totalScore,
      isReady: isReady ?? this.isReady,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      totalScore: json['totalScore'] as int? ?? 0,
      isReady: json['isReady'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatarUrl': avatarUrl,
    'totalScore': totalScore,
    'isReady': isReady,
    'isOnline': isOnline,
  };

  // List<Object?> get props => [id, name, avatarUrl, totalScore, isReady, isOnline];
}

/// Historique d'une partie terminée
class GameHistory{
  final String id;
  final String odId;
  final bool isMultiplayer;
  final int playerCount;
  final int roundsPlayed;
  final int finalScore;
  final int rank; // Position finale (1 = premier)
  final DateTime playedAt;
  final List<String> categories;

  const GameHistory({
    required this.id,
    required this.odId,
    required this.isMultiplayer,
    required this.playerCount,
    required this.roundsPlayed,
    required this.finalScore,
    required this.rank,
    required this.playedAt,
    required this.categories,
  });

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['id'] as String,
      odId: json['odId'] as String,
      isMultiplayer: json['isMultiplayer'] as bool,
      playerCount: json['playerCount'] as int,
      roundsPlayed: json['roundsPlayed'] as int,
      finalScore: json['finalScore'] as int,
      rank: json['rank'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'odId': odId,
    'isMultiplayer': isMultiplayer,
    'playerCount': playerCount,
    'roundsPlayed': roundsPlayed,
    'finalScore': finalScore,
    'rank': rank,
    'playedAt': playedAt.toIso8601String(),
    'categories': categories,
  };

  // List<Object?> get props => [
  //   id, odId, isMultiplayer, playerCount,
  //   roundsPlayed, finalScore, rank, playedAt, categories,
  // ];
}

/// Entrée du leaderboard
class LeaderboardEntry{
  final String odId;
  final String playerName;
  final int totalPoints;
  final int gamesPlayed;
  final int gamesWon;
  final double winRate;

  const LeaderboardEntry({
    required this.odId,
    required this.playerName,
    required this.totalPoints,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.winRate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      odId: json['odId'] as String,
      playerName: json['playerName'] as String,
      totalPoints: json['totalPoints'] as int,
      gamesPlayed: json['gamesPlayed'] as int,
      gamesWon: json['gamesWon'] as int,
      winRate: (json['winRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'odId': odId,
    'playerName': playerName,
    'totalPoints': totalPoints,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
    'winRate': winRate,
  };

  // List<Object?> get props => [
  //   odId, playerName, totalPoints, gamesPlayed, gamesWon, winRate,
  // ];
}

/// ====================================================================
/// SESSION DE VOTE
/// ====================================================================
/// Gère le vote pour un mot non reconnu par le dictionnaire

enum VoteStatus {
  pending,   // En attente de votes
  accepted,  // Majorité accepte
  rejected,  // Majorité refuse
}

class WordVote {
  final String odId;
  final String odName;
  final bool isValid;
  final DateTime votedAt;

  const WordVote({
    required this.odId,
    required this.odName,
    required this.isValid,
    required this.votedAt,
  });

  factory WordVote.fromJson(Map<String, dynamic> json) {
    return WordVote(
      odId: json['odId'] as String,
      odName: json['odName'] as String,
      isValid: json['isValid'] as bool,
      votedAt: DateTime.parse(json['votedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'odId': odId,
    'odName': odName,
    'isValid': isValid,
    'votedAt': votedAt.toIso8601String(),
  };
}

class VoteSession {
  final String id;
  final String odId;
  final String odName;
  final String word;
  final String categoryId;
  final String categoryName;
  final String letter;
  final List<WordVote> votes;
  final VoteStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;

  const VoteSession({
    required this.id,
    required this.odId,
    required this.odName,
    required this.word,
    required this.categoryId,
    required this.categoryName,
    required this.letter,
    this.votes = const [],
    this.status = VoteStatus.pending,
    required this.createdAt,
    this.endedAt,
  });

  /// Nombre de votes "valide"
  int get validVotes => votes.where((v) => v.isValid).length;

  /// Nombre de votes "invalide"
  int get invalidVotes => votes.where((v) => !v.isValid).length;

  /// Total des votes
  int get totalVotes => votes.length;

  /// Vérifie si un joueur a déjà voté
  bool hasVoted(String odId) => votes.any((v) => v.odId == odId);

  factory VoteSession.fromJson(Map<String, dynamic> json) {
    return VoteSession(
      id: json['id'] as String,
      odId: json['odId'] as String,
      odName: json['odName'] as String,
      word: json['word'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      letter: json['letter'] as String,
      votes: (json['votes'] as List?)
          ?.map((v) => WordVote.fromJson(v))
          .toList() ?? [],
      status: VoteStatus.values.firstWhere(
            (s) => s.name == json['status'],
        orElse: () => VoteStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'odId': odId,
    'odName': odName,
    'word': word,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'letter': letter,
    'votes': votes.map((v) => v.toJson()).toList(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };
}
