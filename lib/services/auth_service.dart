import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';

/// Wraps FirebaseAuth. Every public method catches Firebase errors and
/// rethrows a human-readable Exception (screens show it in a SnackBar).
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Sign-in failed. Please try again.');
      // Mark user online (best effort — login already succeeded).
      try {
        await _db.collection(AppConstants.usersCollection).doc(user.uid).update({'online': true});
      } catch (_) {}
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Sign-in failed. Check your connection.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Sign-in failed. Please try again.');
    }
  }

  /// Registers + writes users/{uid} = {name, email, online: true, createdAt}.
  Future<User> signUp({required String name, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw Exception('Registration failed. Please try again.');
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}
      try {
        await _db.collection(AppConstants.usersCollection).doc(user.uid).set({
          'name': name.trim(),
          'email': email.trim(),
          'online': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException catch (e) {
        throw Exception(e.message ?? 'Could not save profile. Try logging in.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registration failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    try {
      if (uid != null) {
        try {
          await _db.collection(AppConstants.usersCollection).doc(uid).update({'online': false});
        } catch (_) {}
      }
      await _auth.signOut();
    } catch (_) {
      // Still try to sign out locally even if Firestore update failed.
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
