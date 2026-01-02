import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/app_provider.dart';
import '../services/vote_service.dart';
import '../themes/app_theme.dart';

/// ====================================================================
/// ÉCRAN DE VOTE
/// ====================================================================
/// Affiche les mots non reconnus et permet aux joueurs de voter.
///
/// Fonctionnement :
/// 1. Affiche chaque mot à valider
/// 2. Les joueurs votent ✅ ou ❌
/// 3. Timer de 15 secondes par mot
/// 4. Résultat affiché après vote
/// ====================================================================

class VoteScreen extends StatefulWidget {
  final String gameId;
  final List<VoteSession> voteSessions;
  final int totalPlayers;

  const VoteScreen({
    super.key,
    required this.gameId,
    required this.voteSessions,
    required this.totalPlayers,
  });

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  // --------------------------------------------------------------
  // VARIABLES
  // --------------------------------------------------------------
  final VoteService _voteService = VoteService();

  int _currentVoteIndex = 0;
  int _remainingTime = VoteService.voteTimeLimit;
  Timer? _timer;
  bool _hasVoted = false;
  bool _isProcessing = false;

  // --------------------------------------------------------------
  // GETTERS
  // --------------------------------------------------------------

  VoteSession? get _currentVote =>
      _currentVoteIndex < widget.voteSessions.length
          ? widget.voteSessions[_currentVoteIndex]
          : null;

  bool get _isLastVote =>
      _currentVoteIndex >= widget.voteSessions.length - 1;

  // --------------------------------------------------------------
  // LIFECYCLE
  // --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --------------------------------------------------------------
  // TIMER
  // --------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    _remainingTime = VoteService.voteTimeLimit;
    _hasVoted = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    if (!_hasVoted) {
      // Auto-skip si pas voté
      _nextVote();
    }
  }

  // --------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------

  /// Soumet le vote du joueur
  Future<void> _submitVote(bool isValid) async {
    if (_hasVoted || _isProcessing || _currentVote == null) return;

    setState(() {
      _hasVoted = true;
      _isProcessing = true;
    });

    final provider = context.read<AppProvider>();
    final odId = provider.odId ?? '';
    final odName = provider.displayName ?? 'Joueur';

    await _voteService.submitVote(
      gameId: widget.gameId,
      voteId: _currentVote!.id,
      odId: odId,
      odName: odName,
      isValid: isValid,
      totalPlayers: widget.totalPlayers,
    );

    setState(() => _isProcessing = false);

    // Attendre 1 seconde pour montrer le résultat
    await Future.delayed(const Duration(seconds: 1));
    _nextVote();
  }

  /// Passe au vote suivant
  void _nextVote() {
    if (_isLastVote) {
      _finishVoting();
    } else {
      setState(() {
        _currentVoteIndex++;
        _hasVoted = false;
      });
      _startTimer();
    }
  }

  /// Termine la session de vote
  void _finishVoting() {
    _timer?.cancel();
    Navigator.of(context).pop(true);
  }

  // --------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_currentVote == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                _buildHeader(),

                const Spacer(),

                // Carte du mot à voter
                _buildVoteCard(),

                const SizedBox(height: 32),

                // Boutons de vote
                if (!_hasVoted) _buildVoteButtons(),

                // Résultat du vote
                if (_hasVoted) _buildVoteResult(),

                const Spacer(),

                // Progression
                _buildProgressIndicator(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // WIDGETS
  // --------------------------------------------------------------

  /// Header avec timer
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Titre
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vote',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_currentVoteIndex + 1}/${widget.voteSessions.length} mot(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),

        // Timer
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _remainingTime <= 5
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: _remainingTime <= 5 ? Colors.red : AppTheme.primaryLight,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              '$_remainingTime',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _remainingTime <= 5 ? Colors.red : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Carte du mot à voter
  Widget _buildVoteCard() {
    final vote = _currentVote!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.2),
            AppTheme.secondaryLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Catégorie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vote.categoryName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Lettre
          Text(
            'Lettre : ${vote.letter.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Mot
          Text(
            vote.word.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Proposé par
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 16, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                'Proposé par ${vote.odName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Boutons de vote
  Widget _buildVoteButtons() {
    return Row(
      children: [
        // Bouton Invalide
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _submitVote(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.close, size: 28),
            label: const Text(
              'Invalide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Bouton Valide
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _submitVote(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.check, size: 28),
            label: const Text(
              'Valide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// Résultat après vote
  Widget _buildVoteResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.accentLight),
          const SizedBox(width: 12),
          Text(
            'Vote enregistré !',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.accentLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Indicateur de progression
  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.voteSessions.length,
            (index) => Container(
          width: index == _currentVoteIndex ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index <= _currentVoteIndex
                ? AppTheme.primaryLight
                : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}