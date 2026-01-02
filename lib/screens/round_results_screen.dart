import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import 'game_screen.dart';
import 'other_screens.dart';
import 'vote_screen.dart';

class RoundResultsScreen extends StatefulWidget {
  const RoundResultsScreen({super.key});

  @override
  State<RoundResultsScreen> createState() => _RoundResultsScreenState();
}

class _RoundResultsScreenState extends State<RoundResultsScreen> {
  bool _voteCompleted = false;
  List<VoteSession> _pendingVotes = [];

  @override
  void initState() {
    super.initState();
    _checkPendingVotes();
  }

  /// Vérifie s'il y a des mots à voter (multijoueur)
  Future<void> _checkPendingVotes() async {
    final provider = context.read<AppProvider>();
    final game = provider.currentGame;

    if (game != null && game.isMultiplayer && !_voteCompleted) {
      final votes = await provider.getPendingVotes(game.id);

      // Filtrer les votes où ce joueur n'a pas encore voté
      final myId = provider.odId ?? '';
      final votesToDo = votes.where((v) =>
      v.odId != myId && !v.hasVoted(myId)
      ).toList();

      if (votesToDo.isNotEmpty && mounted) {
        setState(() => _pendingVotes = votesToDo);
        _showVoteScreen(votesToDo, game);
      }
    }
  }

  /// Affiche l'écran de vote
  Future<void> _showVoteScreen(List<VoteSession> votes, GameSession game) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VoteScreen(
          gameId: game.id,
          voteSessions: votes,
          totalPlayers: game.players.length,
        ),
      ),
    );

    if (mounted) {
      setState(() => _voteCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, _) {
              final game = provider.currentGame;
              if (game == null) return const SizedBox.shrink();

              final currentRound = game.rounds.isNotEmpty
                  ? game.rounds[game.currentRoundIndex]
                  : null;
              if (currentRound == null) return const SizedBox.shrink();

              final playerAnswers = currentRound.playerAnswers[provider.odId] ?? [];
              final roundScore = playerAnswers.fold<int>(
                0, (sum, a) => sum + a.points,
              );

              return Column(
                children: [
                  // Header
                  _buildHeader(context, currentRound, roundScore),

                  // Liste des réponses
                  Expanded(
                    child: _buildAnswersList(
                      context,
                      game.settings.categories,
                      playerAnswers,
                    ),
                  ),

                  // Score total et boutons
                  _buildFooter(context, provider, game),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GameRound round, int roundScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Round ${round.roundNumber} terminé !',
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate().fadeIn().slideY(begin: -0.3),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    round.letter,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().scale(delay: 200.ms),

              const SizedBox(width: 24),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Points gagnés',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '+$roundScore',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentLight,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersList(
      BuildContext context,
      List<Category> categories,
      List<PlayerAnswer> answers,
      ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final answer = answers.firstWhere(
              (a) => a.categoryId == category.id,
          orElse: () => PlayerAnswer(
            categoryId: category.id,
            answer: '',
            isValid: false,
          ),
        );

        return _AnswerResultCard(
          category: category,
          answer: answer,
        ).animate(delay: (index * 100).ms)
            .fadeIn()
            .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppProvider provider, GameSession game) {
    final player = game.players.firstWhere(
          (p) => p.id == provider.odId,
      orElse: () => const Player(id: '', name: ''),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Score total
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Score total: ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${player.totalScore}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
              Text(
                ' pts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),

          // Bouton vote si votes en attente (multijoueur)
          if (_pendingVotes.isNotEmpty && !_voteCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  final game = context.read<AppProvider>().currentGame;
                  if (game != null) {
                    _showVoteScreen(_pendingVotes, game);
                  }
                },
                icon: const Icon(Icons.how_to_vote),
                label: Text('${_pendingVotes.length} mot(s) à voter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ).animate().fadeIn().scale(),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _endGame(context, provider),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Terminer'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _nextRound(context, provider),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Round suivant'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }

  void _nextRound(BuildContext context, AppProvider provider) {
    provider.nextRound();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  void _endGame(BuildContext context, AppProvider provider) {
    provider.endGame();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameOverScreen()),
    );
  }
}

class _AnswerResultCard extends StatelessWidget {
  final Category category;
  final PlayerAnswer answer;

  const _AnswerResultCard({
    required this.category,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswer = answer.answer.isNotEmpty;
    final isValid = answer.isValid;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!hasAnswer) {
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle_outline;
      statusText = 'Pas de réponse';
    } else if (isValid) {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle_rounded;
      statusText = '+${answer.points} pts';
    } else if (!answer.startsWithLetter) {
      statusColor = AppTheme.error;
      statusIcon = Icons.error_outline;
      statusText = 'Mauvaise lettre';
    } else {
      statusColor = AppTheme.warning;
      statusIcon = Icons.help_outline;
      statusText = 'Mot non reconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAnswer ? answer.answer : '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasAnswer ? null : Colors.grey,
                    fontStyle: hasAnswer ? null : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';
// import '../models/game_models.dart';
// import '../providers/app_provider.dart';
// import '../themes/app_theme.dart';
// import 'game_screen.dart';
// import 'other_screens.dart';
//
// class RoundResultsScreen extends StatelessWidget {
//   const RoundResultsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: isDark ? AppTheme.darkBackgroundGradient : null,
//           color: isDark ? null : AppTheme.backgroundLight,
//         ),
//         child: SafeArea(
//           child: Consumer<AppProvider>(
//             builder: (context, provider, _) {
//               final game = provider.currentGame;
//               if (game == null) return const SizedBox.shrink();
//
//               final currentRound = game.rounds.isNotEmpty
//                   ? game.rounds[game.currentRoundIndex]
//                   : null;
//               if (currentRound == null) return const SizedBox.shrink();
//
//               final playerAnswers = currentRound.playerAnswers[provider.odId] ?? [];
//               final roundScore = playerAnswers.fold<int>(
//                 0, (sum, a) => sum + a.points,
//               );
//
//               return Column(
//                 children: [
//                   // Header
//                   _buildHeader(context, currentRound, roundScore),
//
//                   // Liste des réponses
//                   Expanded(
//                     child: _buildAnswersList(
//                       context,
//                       game.settings.categories,
//                       playerAnswers,
//                     ),
//                   ),
//
//                   // Score total et boutons
//                   _buildFooter(context, provider, game),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader(BuildContext context, GameRound round, int roundScore) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Text(
//             'Round ${round.roundNumber} terminé !',
//             style: Theme.of(context).textTheme.headlineSmall,
//           ).animate().fadeIn().slideY(begin: -0.3),
//
//           const SizedBox(height: 24),
//
//           // Lettre jouée
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 80,
//                 height: 80,
//                 decoration: BoxDecoration(
//                   gradient: AppTheme.primaryGradient,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryLight.withOpacity(0.4),
//                       blurRadius: 20,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Text(
//                     round.letter,
//                     style: const TextStyle(
//                       fontSize: 48,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ).animate().scale(delay: 200.ms),
//
//               const SizedBox(width: 24),
//
//               // Score du round
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Points gagnés',
//                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                     ),
//                   ),
//                   Text(
//                     '+$roundScore',
//                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: AppTheme.accentLight,
//                     ),
//                   ),
//                 ],
//               ).animate().fadeIn(delay: 300.ms),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAnswersList(
//       BuildContext context,
//       List<Category> categories,
//       List<PlayerAnswer> answers,
//       ) {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemCount: categories.length,
//       itemBuilder: (context, index) {
//         final category = categories[index];
//         final answer = answers.firstWhere(
//               (a) => a.categoryId == category.id,
//           orElse: () => PlayerAnswer(
//             categoryId: category.id,
//             answer: '',
//             isValid: false,
//           ),
//         );
//
//         return _AnswerResultCard(
//           category: category,
//           answer: answer,
//         ).animate(delay: (index * 100).ms)
//             .fadeIn()
//             .slideX(begin: 0.1);
//       },
//     );
//   }
//
//   Widget _buildFooter(BuildContext context, AppProvider provider, GameSession game) {
//     final player = game.players.firstWhere(
//           (p) => p.id == provider.odId,
//       orElse: () => const Player(id: '', name: ''),
//     );
//
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Score total
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.emoji_events_rounded,
//                 color: AppTheme.warning,
//                 size: 28,
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 'Score total: ',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//               Text(
//                 '${player.totalScore}',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.primaryLight,
//                 ),
//               ),
//               Text(
//                 ' pts',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//             ],
//           ).animate().fadeIn(delay: 400.ms),
//
//           const SizedBox(height: 24),
//
//           // Boutons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _endGame(context, provider),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Text('Terminer'),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 flex: 2,
//                 child: ElevatedButton(
//                   onPressed: () => _nextRound(context, provider),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   child: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('Round suivant'),
//                       SizedBox(width: 8),
//                       Icon(Icons.arrow_forward_rounded),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
//         ],
//       ),
//     );
//   }
//
//   void _nextRound(BuildContext context, AppProvider provider) {
//     provider.nextRound();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const GameScreen()),
//     );
//   }
//
//   void _endGame(BuildContext context, AppProvider provider) {
//     provider.endGame();
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const GameOverScreen()),
//     );
//   }
// }
//
// class _AnswerResultCard extends StatelessWidget {
//   final Category category;
//   final PlayerAnswer answer;
//
//   const _AnswerResultCard({
//     required this.category,
//     required this.answer,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final hasAnswer = answer.answer.isNotEmpty;
//     final isValid = answer.isValid;
//
//     Color statusColor;
//     IconData statusIcon;
//     String statusText;
//
//     if (!hasAnswer) {
//       statusColor = Colors.grey;
//       statusIcon = Icons.remove_circle_outline;
//       statusText = 'Pas de réponse';
//     } else if (isValid) {
//       statusColor = AppTheme.success;
//       statusIcon = Icons.check_circle_rounded;
//       statusText = '+${answer.points} pts';
//     } else if (!answer.startsWithLetter) {
//       statusColor = AppTheme.error;
//       statusIcon = Icons.error_outline;
//       statusText = 'Mauvaise lettre';
//     } else {
//       statusColor = AppTheme.warning;
//       statusIcon = Icons.help_outline;
//       statusText = 'Mot non reconnu';
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: statusColor.withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: Row(
//         children: [
//           // Icône de statut
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               statusIcon,
//               color: statusColor,
//               size: 24,
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           // Catégorie et réponse
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   category.name,
//                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   hasAnswer ? answer.answer : '-',
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: hasAnswer ? null : Colors.grey,
//                     fontStyle: hasAnswer ? null : FontStyle.italic,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Points / Statut
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: statusColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               statusText,
//               style: TextStyle(
//                 color: statusColor,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
