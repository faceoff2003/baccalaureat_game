// ============== JOIN ROOM SCREEN ==============
// lib/screens/join_room_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code doit contenir 6 caractères'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final success = await provider.joinRoom(code);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WaitingRoomScreen()),
      );
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une partie')),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add_rounded,
                  size: 80,
                  color: AppTheme.primaryLight,
                ).animate().scale(),
                const SizedBox(height: 32),
                Text(
                  'Entre le code de la room',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    counterText: '',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                ),
                const SizedBox(height: 32),
                Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _joinRoom,
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Rejoindre'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ============== WAITING ROOM SCREEN ==============

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle d\'attente'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _leaveRoom(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final game = provider.currentGame;
            if (game == null) return const SizedBox.shrink();

            final isHost = game.hostId == provider.odId;

            return Column(
              children: [
                // Code de la room
                _buildRoomCode(context, game.roomCode ?? ''),

                const SizedBox(height: 24),

                // Liste des joueurs
                Expanded(
                  child: _buildPlayersList(context, game.players, provider.odId),
                ),

                // Boutons
                _buildActions(context, provider, game, isHost),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoomCode(BuildContext context, String code) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Code de la room',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié !')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(BuildContext context, List players, String? odId) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player.id == odId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isMe ? Border.all(color: AppTheme.primaryLight, width: 2) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                child: Text(
                  player.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name + (isMe ? ' (Toi)' : ''),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              if (player.isReady)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Prêt',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, AppProvider provider, game, bool isHost) {
    final me = game.players.firstWhere(
          (p) => p.id == provider.odId,
      orElse: () => null,
    );
    final allReady = game.players.every((p) => p.isReady);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isHost)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => provider.setReady(!(me?.isReady ?? false)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: me?.isReady == true ? AppTheme.success : null,
                ),
                child: Text(me?.isReady == true ? 'Annuler' : 'Je suis prêt !'),
              ),
            ),
          if (isHost) ...[
            Text(
              allReady && game.players.length > 1
                  ? 'Tous les joueurs sont prêts !'
                  : 'En attente des joueurs...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allReady && game.players.length > 1
                    ? () => provider.startMultiplayerGame()
                    : null,
                child: const Text('Lancer la partie'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _leaveRoom(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter ?'),
        content: const Text('Voulez-vous vraiment quitter la room ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AppProvider>().leaveGame();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }
}

// ============== GAME OVER SCREEN ==============

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 100,
                    color: AppTheme.warning,
                  ).animate().scale(curve: Curves.elasticOut),
                  const SizedBox(height: 32),
                  Text(
                    'Partie terminée !',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Bravo pour ta performance !',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== LEADERBOARD SCREEN ==============

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: FutureBuilder(
          future: context.read<AppProvider>().getLeaderboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final leaderboard = snapshot.data ?? [];

            if (leaderboard.isEmpty) {
              return const Center(
                child: Text('Aucun classement disponible'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final rank = index + 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: rank <= 3
                        ? Border.all(
                      color: rank == 1
                          ? Colors.amber
                          : rank == 2
                          ? Colors.grey
                          : Colors.brown,
                      width: 2,
                    )
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rank <= 3 ? AppTheme.warning : null,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                        child: Text(
                          entry.playerName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.playerName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${entry.gamesPlayed} parties',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.totalPoints} pts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============== HISTORY SCREEN ==============

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: FutureBuilder(
          future: context.read<AppProvider>().getHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final history = snapshot.data ?? [];

            if (history.isEmpty) {
              return const Center(
                child: Text('Aucune partie jouée'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final game = history[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        game.isMultiplayer ? Icons.group : Icons.person,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.isMultiplayer ? 'Multijoueur' : 'Solo',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${game.roundsPlayed} rounds',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${game.finalScore} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          if (game.isMultiplayer)
                            Text(
                              '#${game.rank}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============== SETTINGS SCREEN ==============

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.darkBackgroundGradient : null,
          color: isDark ? null : AppTheme.backgroundLight,
        ),
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Thème
                _buildSection(
                  context,
                  'Apparence',
                  [
                    SwitchListTile(
                      title: const Text('Mode sombre'),
                      subtitle: const Text('Activer le thème sombre'),
                      value: provider.themeMode == ThemeMode.dark,
                      onChanged: (_) => provider.toggleTheme(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Audio
                _buildSection(
                  context,
                  'Audio',
                  [
                    SwitchListTile(
                      title: const Text('Effets sonores'),
                      value: provider.audioService.soundEnabled,
                      onChanged: (v) => provider.audioService.setSoundEnabled(v),
                    ),
                    SwitchListTile(
                      title: const Text('Musique'),
                      value: provider.audioService.musicEnabled,
                      onChanged: (v) => provider.audioService.setMusicEnabled(v),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Compte
                _buildSection(
                  context,
                  'Compte',
                  [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(provider.displayName ?? 'Utilisateur'),
                      subtitle: Text(provider.email ?? 'Invité'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Version
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
