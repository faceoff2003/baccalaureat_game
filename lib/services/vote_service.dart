import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_models.dart';
import 'dictionary_service.dart';

/// ====================================================================
/// SERVICE DE VOTE
/// ====================================================================
/// Gère le système de vote pour les mots non reconnus.
///
/// Flux :
/// 1. Un mot non trouvé dans le dictionnaire → création VoteSession
/// 2. Les joueurs votent (valide/invalide)
/// 3. Majorité atteinte → mot accepté ou refusé
/// 4. Si accepté → ajout au dictionnaire Firestore
/// ====================================================================

class VoteService {
  // --------------------------------------------------------------
  // SINGLETON
  // --------------------------------------------------------------
  static final VoteService _instance = VoteService._internal();
  factory VoteService() => _instance;
  VoteService._internal();

  // --------------------------------------------------------------
  // DÉPENDANCES
  // --------------------------------------------------------------
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DictionaryService _dictionary = DictionaryService();

  // --------------------------------------------------------------
  // CONSTANTES
  // --------------------------------------------------------------
  /// Temps maximum pour voter (en secondes)
  static const int voteTimeLimit = 15;

  /// Pourcentage minimum pour accepter un mot (50% + 1)
  static const double acceptThreshold = 0.5;

  // --------------------------------------------------------------
  // CRÉATION D'UNE SESSION DE VOTE
  // --------------------------------------------------------------

  /// Crée une nouvelle session de vote pour un mot non reconnu
  Future<VoteSession?> createVoteSession({
    required String gameId,
    required String odId,
    required String odName,
    required String word,
    required String categoryId,
    required String categoryName,
    required String letter,
  }) async {
    try {
      final voteId = '${gameId}_${categoryId}_${word.toLowerCase()}';

      final voteSession = VoteSession(
        id: voteId,
        odId: odId,
        odName: odName,
        word: word.toLowerCase(),
        categoryId: categoryId,
        categoryName: categoryName,
        letter: letter,
        votes: [],
        status: VoteStatus.pending,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('games')
          .doc(gameId)
          .collection('votes')
          .doc(voteId)
          .set(voteSession.toJson());

      print('🗳️ Vote créé: "$word" pour $categoryName');
      return voteSession;

    } catch (e) {
      print('❌ Erreur création vote: $e');
      return null;
    }
  }

  // --------------------------------------------------------------
  // SOUMISSION D'UN VOTE
  // --------------------------------------------------------------

  /// Soumet le vote d'un joueur
  Future<bool> submitVote({
    required String gameId,
    required String voteId,
    required String odId,
    required String odName,
    required bool isValid,
    required int totalPlayers,
  }) async {
    try {
      final voteRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('votes')
          .doc(voteId);

      // Transaction pour éviter les conflits
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(voteRef);

        if (!doc.exists) {
          throw Exception('Vote session not found');
        }

        final session = VoteSession.fromJson(doc.data()!);

        // Vérifier si le joueur a déjà voté
        if (session.hasVoted(odId)) {
          print('⚠️ $odName a déjà voté');
          return;
        }

        // Ajouter le vote
        final newVote = WordVote(
          odId: odId,
          odName: odName,
          isValid: isValid,
          votedAt: DateTime.now(),
        );

        final updatedVotes = [...session.votes, newVote];

        // Calculer le résultat si tous ont voté
        VoteStatus newStatus = VoteStatus.pending;
        DateTime? endedAt;

        if (updatedVotes.length >= totalPlayers - 1) {
          // -1 car le proposeur ne vote pas
          final validCount = updatedVotes.where((v) => v.isValid).length;
          final threshold = (totalPlayers - 1) * acceptThreshold;

          if (validCount >= threshold) {
            newStatus = VoteStatus.accepted;
          } else {
            newStatus = VoteStatus.rejected;
          }
          endedAt = DateTime.now();
        }

        // Mettre à jour
        transaction.update(voteRef, {
          'votes': updatedVotes.map((v) => v.toJson()).toList(),
          'status': newStatus.name,
          'endedAt': endedAt?.toIso8601String(),
        });
      });

      print('✅ Vote soumis par $odName');
      return true;

    } catch (e) {
      print('❌ Erreur soumission vote: $e');
      return false;
    }
  }

  // --------------------------------------------------------------
  // FINALISATION DU VOTE
  // --------------------------------------------------------------

  /// Finalise un vote (appelé après timeout ou majorité)
  Future<VoteStatus> finalizeVote({
    required String gameId,
    required String voteId,
    required int totalPlayers,
  }) async {
    try {
      final voteRef = _firestore
          .collection('games')
          .doc(gameId)
          .collection('votes')
          .doc(voteId);

      final doc = await voteRef.get();
      if (!doc.exists) return VoteStatus.rejected;

      final session = VoteSession.fromJson(doc.data()!);

      // Si déjà finalisé
      if (session.status != VoteStatus.pending) {
        return session.status;
      }

      // Calculer le résultat
      final validCount = session.validVotes;
      final totalVotes = session.totalVotes;

      // Si personne n'a voté → rejeté
      if (totalVotes == 0) {
        await voteRef.update({
          'status': VoteStatus.rejected.name,
          'endedAt': DateTime.now().toIso8601String(),
        });
        return VoteStatus.rejected;
      }

      // Majorité simple
      final threshold = totalVotes * acceptThreshold;
      final newStatus = validCount >= threshold
          ? VoteStatus.accepted
          : VoteStatus.rejected;

      await voteRef.update({
        'status': newStatus.name,
        'endedAt': DateTime.now().toIso8601String(),
      });

      // Si accepté → ajouter au dictionnaire
      if (newStatus == VoteStatus.accepted) {
        await _addWordToDictionary(
          word: session.word,
          categoryId: session.categoryId,
        );
      }

      print('🏁 Vote finalisé: ${session.word} → $newStatus');
      return newStatus;

    } catch (e) {
      print('❌ Erreur finalisation vote: $e');
      return VoteStatus.rejected;
    }
  }

  // --------------------------------------------------------------
  // AJOUT AU DICTIONNAIRE
  // --------------------------------------------------------------

  /// Ajoute un mot validé par vote au dictionnaire Firestore
  Future<void> _addWordToDictionary({
    required String word,
    required String categoryId,
  }) async {
    try {
      // Ajouter dans Firestore (collection partagée)
      await _firestore
          .collection('custom_words')
          .doc(categoryId)
          .collection('words')
          .doc(word.toLowerCase())
          .set({
        'word': word.toLowerCase(),
        'categoryId': categoryId,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': 'vote',
      });

      // Ajouter au dictionnaire local
      _dictionary.addCustomWord(word, categoryId);

      print('📚 Mot ajouté au dictionnaire: $word → $categoryId');

    } catch (e) {
      print('❌ Erreur ajout dictionnaire: $e');
    }
  }

  // --------------------------------------------------------------
  // ÉCOUTE DES VOTES EN TEMPS RÉEL
  // --------------------------------------------------------------

  /// Stream des votes pour une partie
  Stream<List<VoteSession>> watchVotes(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('votes')
        .where('status', isEqualTo: VoteStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VoteSession.fromJson(doc.data()))
        .toList());
  }

  /// Stream d'un vote spécifique
  Stream<VoteSession?> watchVote(String gameId, String voteId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .collection('votes')
        .doc(voteId)
        .snapshots()
        .map((doc) => doc.exists
        ? VoteSession.fromJson(doc.data()!)
        : null);
  }

  // --------------------------------------------------------------
  // CHARGEMENT DES MOTS PERSONNALISÉS
  // --------------------------------------------------------------

  /// Charge tous les mots personnalisés depuis Firestore
  Future<void> loadCustomWords() async {
    try {
      final categories = ['pays', 'ville', 'prenom', 'animal', 'fruit', 'metier', 'objet'];

      for (final categoryId in categories) {
        final snapshot = await _firestore
            .collection('custom_words')
            .doc(categoryId)
            .collection('words')
            .get();

        final words = snapshot.docs.map((doc) => doc.id).toList();

        if (words.isNotEmpty) {
          _dictionary.loadCustomWords(categoryId, words);
        }
      }

      print('✅ Mots personnalisés chargés depuis Firestore');

    } catch (e) {
      print('⚠️ Erreur chargement mots personnalisés: $e');
    }
  }

  // --------------------------------------------------------------
  // RÉCUPÉRATION DES VOTES D'UNE PARTIE
  // --------------------------------------------------------------

  /// Récupère tous les mots à voter pour un round
  Future<List<VoteSession>> getPendingVotes(String gameId) async {
    try {
      final snapshot = await _firestore
          .collection('games')
          .doc(gameId)
          .collection('votes')
          .where('status', isEqualTo: VoteStatus.pending.name)
          .get();

      return snapshot.docs
          .map((doc) => VoteSession.fromJson(doc.data()))
          .toList();

    } catch (e) {
      print('❌ Erreur récupération votes: $e');
      return [];
    }
  }
}