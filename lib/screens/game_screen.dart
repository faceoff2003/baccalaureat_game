import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import 'round_results_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  bool _isSubmitting = false;
  late AnimationController _letterController;
  late AnimationController _pulseController;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  bool _showLetterAnimation = true;

  // @override
  // void initState() {
  //   super.initState();
  //
  //   _letterController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 2000),
  //   );
  //
  //   _pulseController = AnimationController(
  //     vsync: this,
  //     duration: const Duration(milliseconds: 1000),
  //   )..repeat(reverse: true);
  //
  //   // Animation de la lettre au démarrage
  //   _letterController.forward().then((_) {
  //     if (mounted) {
  //       setState(() => _showLetterAnimation = false);
  //     }
  //   });
  //
  //   // Initialiser les controllers pour chaque catégorie
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final game = context.read<AppProvider>().currentGame;
  //     if (game != null) {
  //       for (final category in game.settings.categories) {
  //         _controllers[category.id] = TextEditingController();
  //         _focusNodes[category.id] = FocusNode();
  //       }
  //       setState(() {});
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();

    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Animation de la lettre au démarrage
    _letterController.forward().then((_) {
      if (mounted) {
        setState(() => _showLetterAnimation = false);
      }
    });

    // Initialiser les controllers pour chaque catégorie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<AppProvider>().currentGame;
      if (game != null) {
        for (final category in game.settings.categories) {
          _controllers[category.id] = TextEditingController();
          _focusNodes[category.id] = FocusNode();
        }
        setState(() {});
      }

      // Écouter les changements du provider (pour le timer à 0)
      // context.read<AppProvider>().addListener(_onProviderChange);
    });
  }

  /// Écoute les changements du provider
  /// Soumet automatiquement quand le temps est écoulé
  // void _onProviderChange() {
  //   if (_isSubmitting) return; // Évite la boucle infinie
  //
  //   final provider = context.read<AppProvider>();
  //
  //   if (provider.remainingTime <= 0 &&
  //       provider.currentGame?.status == GameStatus.playing &&
  //       mounted) {
  //     _isSubmitting = true;
  //     _submitAnswers();
  //   }
  // }


  // void _onProviderChange() {
  //   final provider = context.read<AppProvider>();
  //
  //   // Si le temps est à 0 et on est toujours sur cet écran
  //   if (provider.remainingTime <= 0 &&
  //       provider.currentGame?.status == GameStatus.playing &&
  //       mounted) {
  //     _submitAnswers();
  //   }
  // }

  @override
  void dispose() {

    // context.read<AppProvider>().removeListener(_onProviderChange);

    _letterController.dispose();
    _pulseController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _submitAnswers() {
    final provider = context.read<AppProvider>();

    // Collecter les réponses
    for (final entry in _controllers.entries) {
      provider.updateAnswer(entry.key, entry.value.text);
    }

    // Soumettre
    if (provider.currentGame?.isMultiplayer == true) {
      provider.submitMultiplayerAnswers();
    } else {
      provider.submitSoloAnswers();
    }

    // Naviguer vers les résultats
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoundResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final provider = context.watch<AppProvider>();

    // Auto-submit quand le temps est écoulé
    if (provider.remainingTime <= 0 &&
        provider.currentGame?.status == GameStatus.playing &&
        !_isSubmitting) {
      _isSubmitting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submitAnswers();
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: SafeArea(
          bottom: true,
          child: Consumer<AppProvider>(
            builder: (context, provider, _) {
              final game = provider.currentGame;
              if (game == null) return const SizedBox.shrink();

              final currentRound = game.currentRound;
              if (currentRound == null) return const SizedBox.shrink();

              return Column(
                children: [
                  // Header avec timer et lettre
                  _buildHeader(context, provider, currentRound),

                  // Liste des catégories
                  Expanded(
                    child: _showLetterAnimation
                        ? _buildLetterReveal(currentRound.letter)
                        : _buildCategoriesList(game.settings.categories, currentRound.letter),
                  ),

                  // Bouton soumettre
                  if (!_showLetterAnimation)
                    _buildSubmitButton(provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider, GameRound round) {
    final timeRatio = provider.remainingTime /
        (provider.currentGame?.settings.timePerLetter ?? 60);
    final isLowTime = provider.remainingTime <= 10;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Infos round
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round ${round.roundNumber}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.currentGame?.players.length ?? 1} joueur(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Lettre
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: isLowTime
                    ? 1.0 + (_pulseController.value * 0.1)
                    : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  round.letter,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Timer
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: timeRatio,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(
                    isLowTime ? AppTheme.error : AppTheme.accentLight,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${provider.remainingTime}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isLowTime ? AppTheme.error : null,
                      ),
                    ),
                    Text(
                      'sec',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterReveal(String letter) {
    return Center(
      child: AnimatedBuilder(
        animation: _letterController,
        builder: (context, child) {
          // Animation de roulette de lettres
          final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
          final progress = _letterController.value;

          if (progress < 0.8) {
            // Phase de rotation
            final randomIndex = (progress * 50).floor() % letters.length;
            return _buildLetterCard(letters[randomIndex], false);
          } else {
            // Phase finale avec la vraie lettre
            return _buildLetterCard(letter, true)
                .animate()
                .scale(duration: 300.ms, curve: Curves.elasticOut);
          }
        },
      ),
    );
  }

  Widget _buildLetterCard(String letter, bool isFinal) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: isFinal ? AppTheme.primaryGradient : null,
        color: isFinal ? null : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isFinal ? AppTheme.primaryLight : Colors.black).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: isFinal ? Colors.white : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(List<Category> categories, String letter) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];

        return _CategoryInput(
          category: category,
          letter: letter,
          controller: _controllers[category.id] ?? TextEditingController(),
          focusNode: _focusNodes[category.id] ?? FocusNode(),
          onNext: index < categories.length - 1
              ? () => _focusNodes[categories[index + 1].id]?.requestFocus()
              : null,
        ).animate(delay: (index * 50).ms)
            .fadeIn()
            .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildSubmitButton(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _submitAnswers,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentLight,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded),
              SizedBox(width: 8),
              Text('Valider mes réponses'),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.3);
  }
}

class _CategoryInput extends StatelessWidget {
  final Category category;
  final String letter;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onNext;

  const _CategoryInput({
    required this.category,
    required this.letter,
    required this.controller,
    required this.focusNode,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Commence par "$letter"...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryLight,
                  width: 2,
                ),
              ),
            ),
            textInputAction: onNext != null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: (_) => onNext?.call(),
          ),
        ],
      ),
    );
  }
}
