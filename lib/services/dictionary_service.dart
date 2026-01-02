import 'dart:convert';
import 'package:flutter/services.dart';

/// ====================================================================
/// SERVICE DE VALIDATION DES MOTS
/// ====================================================================
/// Ce service gère la validation des réponses des joueurs en utilisant
/// des dictionnaires spécialisés par catégorie.
///
/// Stratégie de validation :
/// 1. Vérification primaire (longueur + première lettre)
/// 2. Recherche dans le dictionnaire de la catégorie
/// 3. Si non trouvé → vote des joueurs (multijoueur)
/// 4. Mots validés par vote → ajoutés à Firestore
/// ====================================================================

class DictionaryService {
  // --------------------------------------------------------------
  // SINGLETON
  // --------------------------------------------------------------
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  // --------------------------------------------------------------
  // DICTIONNAIRES EN MÉMOIRE
  // --------------------------------------------------------------
  /// Map des dictionnaires : categoryId → Set de mots
  final Map<String, Set<String>> _dictionaries = {};

  /// Dictionnaire général (fallback)
  Set<String> _generalDictionary = {};

  /// Mots personnalisés ajoutés par les joueurs (depuis Firestore)
  final Map<String, Set<String>> _customWords = {};

  // --------------------------------------------------------------
  // ÉTAT
  // --------------------------------------------------------------
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;

  // --------------------------------------------------------------
  // MAPPING CATÉGORIE → FICHIER
  // --------------------------------------------------------------
  /// Associe chaque catégorie à son fichier dictionnaire
  static const Map<String, String> _categoryFiles = {
    'pays': 'pays.json',
    'ville': 'villes.json',
    'prenom': 'prenoms.json',
    'animal': 'animaux.json',
    'fruit': 'fruits_legumes.json',
    'legume': 'fruits_legumes.json',
    'metier': 'metiers.json',
    'objet': 'objets.json',
  };

  // --------------------------------------------------------------
  // CHARGEMENT DES DICTIONNAIRES
  // --------------------------------------------------------------

  /// Charge tous les dictionnaires depuis les assets
  Future<void> loadDictionaries() async {
    if (_isLoaded || _isLoading) return;

    _isLoading = true;

    try {
      // Charger chaque dictionnaire spécialisé
      for (final entry in _categoryFiles.entries) {
        await _loadDictionary(entry.key, entry.value);
      }

      // Charger le dictionnaire général
      await _loadGeneralDictionary();

      _isLoaded = true;
      print('✅ Dictionnaires chargés avec succès');

    } catch (e) {
      print('❌ Erreur chargement dictionnaires: $e');
      _loadFallbackDictionaries();
    } finally {
      _isLoading = false;
    }
  }

  /// Charge un dictionnaire spécifique
  Future<void> _loadDictionary(String categoryId, String fileName) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/dictionaries/$fileName',
      );
      final List<dynamic> words = json.decode(jsonString);

      // Convertir en Set avec mots normalisés
      _dictionaries[categoryId] = words
          .map((w) => _normalizeWord(w.toString()))
          .toSet();

      print('📚 $categoryId: ${_dictionaries[categoryId]!.length} mots');

    } catch (e) {
      print('⚠️ Erreur chargement $fileName: $e');
      _dictionaries[categoryId] = {};
    }
  }

  /// Charge le dictionnaire général (fallback)
  Future<void> _loadGeneralDictionary() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/dictionaries/general.json',
      );
      final List<dynamic> words = json.decode(jsonString);

      _generalDictionary = words
          .map((w) => _normalizeWord(w.toString()))
          .toSet();

      print('📚 general: ${_generalDictionary.length} mots');

    } catch (e) {
      print('⚠️ Erreur chargement general.json: $e');
      _generalDictionary = {};
    }
  }

  /// Dictionnaires de secours si le chargement échoue
  void _loadFallbackDictionaries() {
    _dictionaries['pays'] = {
      'france', 'espagne', 'italie', 'allemagne', 'belgique',
      'maroc', 'algerie', 'tunisie', 'portugal', 'suisse',
    };

    _dictionaries['prenom'] = {
      'adam', 'marie', 'pierre', 'sophie', 'lucas',
      'emma', 'hugo', 'lea', 'louis', 'chloe',
    };

    _dictionaries['animal'] = {
      'chat', 'chien', 'lion', 'tigre', 'elephant',
      'girafe', 'zebre', 'ours', 'loup', 'renard',
    };

    _generalDictionary = {'maison', 'voiture', 'table', 'livre', 'ecole'};

    _isLoaded = true;
    print('⚠️ Dictionnaires fallback chargés');
  }

  // --------------------------------------------------------------
  // NORMALISATION DES MOTS
  // --------------------------------------------------------------

  /// Normalise un mot : minuscules, sans accents, sans espaces
  /// Permet de comparer "Élève" avec "eleve"
  String _normalizeWord(String word) {
    return word
        .toLowerCase()
        .trim()
    // Accents
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('œ', 'oe')
        .replaceAll('æ', 'ae')
    // Caractères spéciaux
        .replaceAll('-', '')
        .replaceAll("'", '')
        .replaceAll(' ', '');
  }

  // --------------------------------------------------------------
  // VÉRIFICATION DES MOTS
  // --------------------------------------------------------------

  /// Vérifie si un mot existe dans le dictionnaire d'une catégorie
  /// Retourne true si trouvé dans :
  /// 1. Le dictionnaire de la catégorie
  /// 2. Les mots personnalisés de la catégorie
  /// 3. Le dictionnaire général (fallback)
  bool wordExists(String word, String categoryId) {
    if (!_isLoaded) return true; // Accepter par défaut si non chargé

    final normalized = _normalizeWord(word);
    final categoryKey = _getCategoryKey(categoryId);

    // 1. Vérifier le dictionnaire de la catégorie
    if (_dictionaries[categoryKey]?.contains(normalized) ?? false) {
      return true;
    }

    // 2. Vérifier les mots personnalisés
    if (_customWords[categoryKey]?.contains(normalized) ?? false) {
      return true;
    }

    // 3. Fallback : dictionnaire général
    if (_generalDictionary.contains(normalized)) {
      return true;
    }

    return false;
  }

  /// Vérifie si un mot commence par la lettre donnée
  bool startsWithLetter(String word, String letter) {
    if (word.isEmpty) return false;

    final normalizedWord = _normalizeWord(word);
    final normalizedLetter = _normalizeWord(letter);

    return normalizedWord.startsWith(normalizedLetter);
  }

  /// Retourne la clé de catégorie normalisée
  /// Ex: "Fruit/Légume" → "fruit"
  String _getCategoryKey(String categoryId) {
    final normalized = categoryId.toLowerCase();

    // Mapping des variations possibles
    if (normalized.contains('pays')) return 'pays';
    if (normalized.contains('ville')) return 'ville';
    if (normalized.contains('prenom') || normalized.contains('prénom')) return 'prenom';
    if (normalized.contains('animal') || normalized.contains('animaux')) return 'animal';
    if (normalized.contains('fruit') || normalized.contains('legume') || normalized.contains('légume')) return 'fruit';
    if (normalized.contains('metier') || normalized.contains('métier')) return 'metier';
    if (normalized.contains('objet')) return 'objet';

    return normalized;
  }

  // --------------------------------------------------------------
  // VALIDATION COMPLÈTE D'UNE RÉPONSE
  // --------------------------------------------------------------

  /// Valide une réponse complète
  /// Retourne un objet ValidationResult avec tous les détails
  ValidationResult validateAnswer({
    required String answer,
    required String letter,
    required String categoryId,
    required int minLength,
  }) {
    final trimmedAnswer = answer.trim();

    // 1. Vérification longueur minimum
    if (trimmedAnswer.length < minLength) {
      return ValidationResult(
        isValid: false,
        startsWithLetter: false,
        existsInDictionary: false,
        needsVote: false,
        errorMessage: 'Réponse trop courte (min. $minLength caractères)',
      );
    }

    // 2. Vérification première lettre
    final startsCorrectly = startsWithLetter(trimmedAnswer, letter);
    if (!startsCorrectly) {
      return ValidationResult(
        isValid: false,
        startsWithLetter: false,
        existsInDictionary: false,
        needsVote: false,
        errorMessage: 'Doit commencer par la lettre "$letter"',
      );
    }

    // 3. Vérification dans le dictionnaire
    final exists = wordExists(trimmedAnswer, categoryId);

    if (exists) {
      // ✅ Mot trouvé → valide
      return ValidationResult(
        isValid: true,
        startsWithLetter: true,
        existsInDictionary: true,
        needsVote: false,
      );
    } else {
      // ⚠️ Mot non trouvé → nécessite un vote
      return ValidationResult(
        isValid: false,
        startsWithLetter: true,
        existsInDictionary: false,
        needsVote: true,
        errorMessage: 'Mot non reconnu - soumis au vote',
      );
    }
  }

  // --------------------------------------------------------------
  // CALCUL DES POINTS
  // --------------------------------------------------------------

  /// Calcule les points pour une réponse
  /// - 10 pts : réponse valide
  /// - +5 pts : réponse unique (personne d'autre n'a la même)
  /// - +1 pt par caractère au-delà de 5
  int calculatePoints({
    required String answer,
    required bool isValid,
    required bool isUnique,
  }) {
    if (!isValid) return 0;

    int points = 10;

    // Bonus réponse unique
    if (isUnique) {
      points += 5;
    }

    // Bonus longueur
    if (answer.length > 5) {
      points += answer.length - 5;
    }

    return points;
  }

  // --------------------------------------------------------------
  // GESTION DES MOTS PERSONNALISÉS
  // --------------------------------------------------------------

  /// Ajoute un mot validé par vote au dictionnaire personnalisé
  void addCustomWord(String word, String categoryId) {
    final normalized = _normalizeWord(word);
    final categoryKey = _getCategoryKey(categoryId);

    _customWords.putIfAbsent(categoryKey, () => {});
    _customWords[categoryKey]!.add(normalized);

    print('➕ Mot ajouté: $normalized → $categoryKey');
  }

  /// Charge les mots personnalisés depuis une liste (Firestore)
  void loadCustomWords(String categoryId, List<String> words) {
    final categoryKey = _getCategoryKey(categoryId);

    _customWords[categoryKey] = words
        .map((w) => _normalizeWord(w))
        .toSet();

    print('📥 $categoryKey: ${words.length} mots personnalisés chargés');
  }

  // --------------------------------------------------------------
  // STATISTIQUES (DEBUG)
  // --------------------------------------------------------------

  /// Retourne les statistiques des dictionnaires chargés
  Map<String, int> getStats() {
    final stats = <String, int>{};

    for (final entry in _dictionaries.entries) {
      stats[entry.key] = entry.value.length;
    }
    stats['general'] = _generalDictionary.length;

    // Mots personnalisés
    int customTotal = 0;
    for (final entry in _customWords.entries) {
      customTotal += entry.value.length;
    }
    stats['custom_total'] = customTotal;

    return stats;
  }
}

// ======================================================================
// RÉSULTAT DE VALIDATION
// ======================================================================

/// Contient le résultat détaillé d'une validation de réponse
class ValidationResult {
  final bool isValid;
  final bool startsWithLetter;
  final bool existsInDictionary;
  final bool needsVote;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    required this.startsWithLetter,
    required this.existsInDictionary,
    required this.needsVote,
    this.errorMessage,
  });
}







// import 'dart:convert';
// import 'package:flutter/services.dart';
//
// /// Service de validation des mots via dictionnaire local
// /// Utilise un fichier JSON embarqué pour une validation instantanée (0 latence)
// class DictionaryService {
//   static final DictionaryService _instance = DictionaryService._internal();
//   factory DictionaryService() => _instance;
//   DictionaryService._internal();
//
//   Set<String> _dictionary = {};
//   bool _isLoaded = false;
//   bool _isLoading = false;
//
//   bool get isLoaded => _isLoaded;
//
//   /// Charge le dictionnaire depuis les assets
//   Future<void> loadDictionary() async {
//     if (_isLoaded || _isLoading) return;
//
//     _isLoading = true;
//
//     try {
//       final String jsonString = await rootBundle.loadString(
//         'assets/data/french_dictionary.json',
//       );
//       final List<dynamic> words = json.decode(jsonString);
//
//       // Convertir en Set pour recherche O(1)
//       _dictionary = words
//           .map((w) => _normalizeWord(w.toString()))
//           .toSet();
//
//       _isLoaded = true;
//       print('Dictionnaire chargé: ${_dictionary.length} mots');
//     } catch (e) {
//       print('Erreur chargement dictionnaire: $e');
//       // Charger un dictionnaire minimal en fallback
//       _loadFallbackDictionary();
//     } finally {
//       _isLoading = false;
//     }
//   }
//
//   /// Dictionnaire de secours avec mots courants
//   void _loadFallbackDictionary() {
//     _dictionary = {
//       // Prénoms courants
//       'adam', 'alice', 'antoine', 'arthur', 'benjamin', 'camille', 'charlotte',
//       'david', 'emma', 'gabriel', 'hugo', 'jules', 'lea', 'louis', 'lucas',
//       'marie', 'nathan', 'nicolas', 'paul', 'pierre', 'raphael', 'sarah',
//       'thomas', 'victor', 'zoe',
//
//       // Pays
//       'france', 'allemagne', 'espagne', 'italie', 'belgique', 'suisse',
//       'portugal', 'angleterre', 'japon', 'chine', 'maroc', 'algerie',
//       'tunisie', 'canada', 'bresil', 'argentine', 'mexique', 'australie',
//
//       // Villes
//       'paris', 'lyon', 'marseille', 'bordeaux', 'lille', 'toulouse',
//       'nice', 'nantes', 'strasbourg', 'montpellier', 'bruxelles', 'geneve',
//
//       // Animaux
//       'chat', 'chien', 'lion', 'tigre', 'elephant', 'girafe', 'zebre',
//       'ours', 'loup', 'renard', 'lapin', 'souris', 'serpent', 'aigle',
//       'poisson', 'dauphin', 'baleine', 'requin', 'tortue', 'crocodile',
//
//       // Fruits
//       'pomme', 'poire', 'banane', 'orange', 'citron', 'fraise', 'cerise',
//       'peche', 'abricot', 'raisin', 'melon', 'pasteque', 'ananas', 'mangue',
//
//       // Objets
//       'table', 'chaise', 'lit', 'armoire', 'lampe', 'miroir', 'telephone',
//       'ordinateur', 'television', 'voiture', 'velo', 'livre', 'stylo',
//       'cahier', 'sac', 'montre', 'lunettes', 'parapluie',
//
//       // Métiers
//       'medecin', 'avocat', 'professeur', 'ingenieur', 'architecte',
//       'boulanger', 'boucher', 'coiffeur', 'dentiste', 'infirmier',
//       'journaliste', 'musicien', 'peintre', 'plombier', 'policier',
//     };
//     _isLoaded = true;
//     print('Dictionnaire fallback chargé: ${_dictionary.length} mots');
//   }
//
//   /// Normalise un mot (minuscules, sans accents)
//   String _normalizeWord(String word) {
//     return word
//         .toLowerCase()
//         .replaceAll('é', 'e')
//         .replaceAll('è', 'e')
//         .replaceAll('ê', 'e')
//         .replaceAll('ë', 'e')
//         .replaceAll('à', 'a')
//         .replaceAll('â', 'a')
//         .replaceAll('ä', 'a')
//         .replaceAll('ù', 'u')
//         .replaceAll('û', 'u')
//         .replaceAll('ü', 'u')
//         .replaceAll('î', 'i')
//         .replaceAll('ï', 'i')
//         .replaceAll('ô', 'o')
//         .replaceAll('ö', 'o')
//         .replaceAll('ç', 'c')
//         .replaceAll('œ', 'oe')
//         .replaceAll('æ', 'ae')
//         .trim();
//   }
//
//   /// Vérifie si un mot existe dans le dictionnaire
//   bool wordExists(String word) {
//     if (!_isLoaded) return true; // Accepter par défaut si non chargé
//
//     final normalized = _normalizeWord(word);
//     return _dictionary.contains(normalized);
//   }
//
//   /// Vérifie si un mot commence par la lettre donnée
//   bool startsWithLetter(String word, String letter) {
//     if (word.isEmpty) return false;
//
//     final normalizedWord = _normalizeWord(word);
//     final normalizedLetter = _normalizeWord(letter);
//
//     return normalizedWord.startsWith(normalizedLetter);
//   }
//
//   /// Validation complète d'une réponse
//   ValidationResult validateAnswer({
//     required String answer,
//     required String letter,
//     required int minLength,
//   }) {
//     final trimmedAnswer = answer.trim();
//
//     // Vérification longueur minimum
//     if (trimmedAnswer.length < minLength) {
//       return ValidationResult(
//         isValid: false,
//         startsWithLetter: false,
//         existsInDictionary: false,
//         errorMessage: 'Réponse trop courte (min. $minLength caractères)',
//       );
//     }
//
//     // Vérification première lettre
//     final startsCorrectly = startsWithLetter(trimmedAnswer, letter);
//     if (!startsCorrectly) {
//       return ValidationResult(
//         isValid: false,
//         startsWithLetter: false,
//         existsInDictionary: false,
//         errorMessage: 'Doit commencer par la lettre "$letter"',
//       );
//     }
//
//     // Vérification existence dans dictionnaire
//     final exists = wordExists(trimmedAnswer);
//
//     return ValidationResult(
//       isValid: exists,
//       startsWithLetter: true,
//       existsInDictionary: exists,
//       errorMessage: exists ? null : 'Mot non reconnu dans le dictionnaire',
//     );
//   }
//
//   /// Calcule les points pour une réponse
//   int calculatePoints({
//     required String answer,
//     required bool isValid,
//     required bool isUnique, // Aucun autre joueur n'a la même réponse
//   }) {
//     if (!isValid) return 0;
//
//     // Points de base
//     int points = 10;
//
//     // Bonus si réponse unique
//     if (isUnique) {
//       points += 5;
//     }
//
//     // Bonus longueur (1 point par caractère au-delà de 5)
//     if (answer.length > 5) {
//       points += answer.length - 5;
//     }
//
//     return points;
//   }
// }
//
// /// Résultat de validation d'une réponse
// class ValidationResult {
//   final bool isValid;
//   final bool startsWithLetter;
//   final bool existsInDictionary;
//   final String? errorMessage;
//
//   const ValidationResult({
//     required this.isValid,
//     required this.startsWithLetter,
//     required this.existsInDictionary,
//     this.errorMessage,
//   });
// }
