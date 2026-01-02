import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service d'authentification avec Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Utilisateur courant
  User? get currentUser => _auth.currentUser;

  /// Stream de changements d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inscription avec email/mot de passe
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le nom d'affichage
      await credential.user?.updateDisplayName(displayName);

      // Créer le profil utilisateur dans Firestore
      if (credential.user != null) {
        await _createUserProfile(credential.user!, displayName);
      }

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Une erreur est survenue: $e');
    }
  }

  /// Connexion avec email/mot de passe
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le statut en ligne
      if (credential.user != null) {
        await _updateOnlineStatus(credential.user!.uid, true);
      }

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Une erreur est survenue: $e');
    }
  }

  /// Connexion anonyme (pour jouer sans compte)
  Future<AuthResult> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();

      // Créer un profil temporaire
      if (credential.user != null) {
        final guestName = 'Joueur_${credential.user!.uid.substring(0, 6)}';
        await credential.user?.updateDisplayName(guestName);
        await _createUserProfile(credential.user!, guestName, isGuest: true);
      }

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Une erreur est survenue: $e');
    }
  }

  /// Connexion avec Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.error('Connexion annulée');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          await _createUserProfile(user, user.displayName ?? 'Joueur');
        } else {
          await _updateOnlineStatus(user.uid, true);
        }
      }

      return AuthResult.success(userCredential.user);
    } catch (e) {
      return AuthResult.error('Erreur de connexion Google');
    }
  }


  /// Déconnexion
  Future<void> signOut() async {
    if (currentUser != null) {
      await _updateOnlineStatus(currentUser!.uid, false);
    }
    await _auth.signOut();
  }

  /// Réinitialisation du mot de passe
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null,
          message: 'Email de réinitialisation envoyé');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Une erreur est survenue: $e');
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final user = currentUser;
    if (user == null) return;

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Mettre à jour Firestore
    await _firestore.collection('users').doc(user.uid).update({
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Créer le profil utilisateur dans Firestore
  Future<void> _createUserProfile(
      User user,
      String displayName, {
        bool isGuest = false,
      }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'photoUrl': user.photoURL,
      'isGuest': isGuest,
      'isOnline': true,
      'totalPoints': 0,
      'gamesPlayed': 0,
      'gamesWon': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mettre à jour le statut en ligne
  Future<void> _updateOnlineStatus(String odId, bool isOnline) async {
    await _firestore.collection('users').doc(odId).update({
      'isOnline': isOnline,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtenir le profil utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserProfile(String odId) async {
    final doc = await _firestore.collection('users').doc(odId).get();
    return doc.data();
  }

  /// Obtenir les messages d'erreur en français
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      default:
        return 'Une erreur est survenue ($code)';
    }
  }
}

/// Résultat d'une opération d'authentification
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      successMessage: message,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
