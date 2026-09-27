import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Kullanıcıya gösterilecek kimlik doğrulama hatası.
class SignInException implements Exception {
  SignInException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw SignInException(_tr(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw SignInException(_tr(e));
    }

    final user = cred.user;
    if (user == null) throw SignInException('Could not create the account.');

    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        await user.updateDisplayName(name);
      } on FirebaseAuthException {
        // Profil adı yazılamazsa kaydı yine de sürdür.
      }
    }

    // `users/{uid}` — doküman ID'si Auth UID.
    try {
      await _db.collection('users').doc(user.uid).set({
        if (name != null && name.isNotEmpty) 'full_name': name,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Oluşturulamazsa profil upsert sırasında yeniden denenir.
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _tr(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'network-request-failed':
        return 'Could not connect. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email and password sign-in are disabled for this project.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      case 'requires-recent-login':
        return 'Please sign in again for security.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
