import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/app_provider.dart';
import '../services/game_service.dart';
import '../themes/app_theme.dart';
import 'game_screen.dart';
import 'other_screens.dart';

class GameSetupScreen extends StatefulWidget {
  final bool isMultiplayer;

  const GameSetupScreen({
    super.key,
    required this.isMultiplayer,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  // Paramètres
  int _timePerLetter = 60;
  final Set<String> _bannedLetters = {};
  bool _easyMode = false;
  final List<Category> _selectedCategories = [];
  final List<Category> _customCategories = [];

  // Controller pour nouvelles catégories
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Catégories par défaut sélectionnées
    _selectedCategories.addAll(GameService.defaultCategories);
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    final provider = context.read<AppProvider>();

    // final settings = GameSettings(
    //   timePerLetter: _timePerLetter,
    //   bannedLetters: _bannedLetters.toList(),
    //   categories: _selectedCategories,
    //   minWordLength: 2,
    //);

    final settings = GameSettings(
      timePerLetter: _timePerLetter,
      bannedLetters: _bannedLetters.toList(),
      categories: _selectedCategories,
      minWordLength: 2,
      easyMode: _easyMode,
    );

    if (widget.isMultiplayer) {
      final roomCode = await provider.createMultiplayerRoom(settings);
      if (roomCode != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
        );
      }
    } else {
      await provider.startSoloGame(settings);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMultiplayer
            ? 'Nouvelle partie multi'
            : 'Nouvelle partie solo'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Temps par lettre
              _buildTimeSelector()
                  .animate()
                  .fadeIn()
                  .slideX(begin: -0.1),

              const SizedBox(height: 32),

              // Catégories
              _buildCategoriesSection()
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.1),

              const SizedBox(height: 32),

              // Lettres bannies
              _buildBannedLettersSection()
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.1),

              const SizedBox(height: 40),

              // Mode facile
              _buildEasyModeSection()
                  .animate()
                  .fadeIn(delay: 250.ms)
                  .slideX(begin: -0.1),

              const SizedBox(height: 32),

              // Bouton démarrer
              _buildStartButton()
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2),

              // Espace pour la barre de navigation
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Mode Facile
  /// Permet d'ignorer les accents et majuscules
  Widget _buildEasyModeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.child_care_rounded,
                size: 20,
                color: _easyMode ? AppTheme.accentLight : null,
              ),
              const SizedBox(width: 8),
              Text(
                'Mode facile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: _easyMode,
                onChanged: (value) {
                  setState(() => _easyMode = value);
                },
                activeColor: AppTheme.accentLight,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Idéal pour les enfants et débutants :\n'
                '• Ignore les accents (é = e)\n'
                '• Ignore les majuscules\n'
                '• Ignore les tirets et espaces',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Temps par lettre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_timePerLetter',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'secondes',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: _timePerLetter.toDouble(),
                min: 30,
                max: 180,
                divisions: 15,
                label: '$_timePerLetter s',
                onChanged: (value) {
                  setState(() => _timePerLetter = value.round());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30s', style: Theme.of(context).textTheme.bodySmall),
                  Text('180s', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Catégories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Catégories par défaut
              ...GameService.defaultCategories.map((cat) => _CategoryChip(
                category: cat,
                isSelected: _selectedCategories.contains(cat),
                onToggle: () => _toggleCategory(cat),
              )),
              // Catégories personnalisées
              ..._customCategories.map((cat) => _CategoryChip(
                category: cat,
                isSelected: _selectedCategories.contains(cat),
                onToggle: () => _toggleCategory(cat),
                onDelete: () => _removeCustomCategory(cat),
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedCategories.length} catégorie(s) sélectionnée(s)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBannedLettersSection() {
    const letters = GameService.availableLetters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.block_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lettres bannies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionne les lettres que tu veux exclure',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: letters.map((letter) {
              final isBanned = _bannedLetters.contains(letter);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isBanned) {
                      _bannedLetters.remove(letter);
                    } else {
                      _bannedLetters.add(letter);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isBanned
                        ? AppTheme.error.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBanned
                          ? AppTheme.error
                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: isBanned ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isBanned
                            ? AppTheme.error
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: isBanned
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_bannedLetters.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${_bannedLetters.length} lettre(s) bannie(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStartButton() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final canStart = _selectedCategories.isNotEmpty;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canStart && !provider.isLoading ? _startGame : null,
            child: provider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.isMultiplayer
                    ? Icons.group_add_rounded
                    : Icons.play_arrow_rounded),
                const SizedBox(width: 8),
                Text(widget.isMultiplayer
                    ? 'Créer la partie'
                    : 'Commencer'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleCategory(Category category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _removeCustomCategory(Category category) {
    setState(() {
      _customCategories.remove(category);
      _selectedCategories.remove(category);
    });
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'Ex: Film, Marque, Célébrité...',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _categoryController.text.trim();
              if (name.isNotEmpty) {
                final newCategory = Category(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                );
                setState(() {
                  _customCategories.add(newCategory);
                  _selectedCategories.add(newCategory);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onDelete != null && !category.isDefault) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
