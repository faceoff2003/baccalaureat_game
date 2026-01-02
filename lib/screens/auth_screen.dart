import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    super.dispose();
  }

  // Future<void> _handleLogin() async {
  //   if (!_loginFormKey.currentState!.validate()) return;
  //
  //   final provider = context.read<AppProvider>();
  //   final success = await provider.signIn(
  //     email: _loginEmailController.text.trim(),
  //     password: _loginPasswordController.text,
  //   );
  //
  //   if (success && mounted) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else if (mounted && provider.errorMessage != null) {
  //     _showError(provider.errorMessage!);
  //   }
  // }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final success = await provider.signIn(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else if (mounted && provider.errorMessage != null) {
      _showError(provider.errorMessage!);
    }
  }

  // Future<void> _handleSignup() async {
  //   if (!_signupFormKey.currentState!.validate()) return;
  //
  //   final provider = context.read<AppProvider>();
  //   final success = await provider.signUp(
  //     email: _signupEmailController.text.trim(),
  //     password: _signupPasswordController.text,
  //     displayName: _signupNameController.text.trim(),
  //   );
  //
  //   if (success && mounted) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else if (mounted && provider.errorMessage != null) {
  //     _showError(provider.errorMessage!);
  //   }
  // }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final success = await provider.signUp(
      email: _signupEmailController.text.trim(),
      password: _signupPasswordController.text,
      displayName: _signupNameController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else if (mounted && provider.errorMessage != null) {
      _showError(provider.errorMessage!);
    }
  }

  // Future<void> _handleGuestLogin() async {
  //   final provider = context.read<AppProvider>();
  //   final success = await provider.signInAnonymously();
  //
  //   if (success && mounted) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else if (mounted && provider.errorMessage != null) {
  //     _showError(provider.errorMessage!);
  //   }
  // }

  Future<void> _handleGuestLogin() async {
    final provider = context.read<AppProvider>();
    final success = await provider.signInAnonymously();

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else if (mounted && provider.errorMessage != null) {
      _showError(provider.errorMessage!);
    }
  }

  // Future<void> _handleGoogleLogin() async {
  //   final provider = context.read<AppProvider>();
  //   final success = await provider.signInWithGoogle();
  //
  //   if (success && mounted) {
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else if (mounted && provider.errorMessage != null) {
  //     _showError(provider.errorMessage!);
  //   }
  // }

  Future<void> _handleGoogleLogin() async {
    final provider = context.read<AppProvider>();
    final success = await provider.signInWithGoogle();

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else if (mounted && provider.errorMessage != null) {
      _showError(provider.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
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
          bottom: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Titre
                  _buildHeader().animate().fadeIn().slideY(begin: -0.3),

                  const SizedBox(height: 20),

                  // Tabs
                  _buildTabBar().animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // Formulaires
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm().animate().fadeIn(delay: 300.ms),
                        _buildSignupForm().animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton invité
                  _buildGuestButton().animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'B',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Baccalauréat',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Le jeu de mots classique',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Connexion'),
          Tab(text: 'Inscription'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez votre mot de passe';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _handleLogin,
                  child: provider.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Se connecter'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _signupNameController,
              decoration: const InputDecoration(
                labelText: 'Pseudo',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Entrez un pseudo';
                }
                if (value.length < 3) {
                  return 'Minimum 3 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Entrez votre email';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Entrez un mot de passe';
                }
                if (value.length < 6) {
                  return 'Minimum 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _signupConfirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
              validator: (value) {
                if (value != _signupPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleSignup,
                    child: provider.isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('S\'inscrire'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: TextStyle(color: Colors.grey.withOpacity(0.6)),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 24),
        // Bouton Google
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleGoogleLogin,
            // icon: Image.network(
            //   'https://www.google.com/favicon.ico',
            //   width: 24,
            //   height: 24,
            // ),

            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Continuer avec Google'),
          ),
        ),
        const SizedBox(height: 12),
        // Bouton invité
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleGuestLogin,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Jouer en tant qu\'invité'),
          ),
        ),
      ],
    );
  }

  // Widget _buildGuestButton() {
  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 16),
  //             child: Text(
  //               'ou',
  //               style: TextStyle(color: Colors.grey.withOpacity(0.6)),
  //             ),
  //           ),
  //           Expanded(child: Divider(color: Colors.grey.withOpacity(0.3))),
  //         ],
  //       ),
  //       const SizedBox(height: 24),
  //       SizedBox(
  //         width: double.infinity,
  //         child: OutlinedButton.icon(
  //           onPressed: _handleGuestLogin,
  //           icon: const Icon(Icons.play_arrow_rounded),
  //           label: const Text('Jouer en tant qu\'invité'),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre email pour recevoir un lien de réinitialisation.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final provider = context.read<AppProvider>();
                final success = await provider.resetPassword(
                  emailController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Email envoyé !'
                          : provider.errorMessage ?? 'Erreur'),
                      backgroundColor: success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
