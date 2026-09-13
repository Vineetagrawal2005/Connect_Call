import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/user_model.dart';

/// Reads/writes the `users` collection. All calls are try/catch-wrapped;
/// screens surface failures with a SnackBar.
class UserService {
  final FirebaseFirestore _db;

  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Every registered user, newest first. Screens filter out the current user.
  Stream<List<AppUser>> streamAllUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }

  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  Future<void> setOnline(String uid, bool online) async {
    try {
      await _db.collection(AppConstants.usersCollection).doc(uid).update({'online': online});
    } catch (e) {
      throw Exception('Could not update presence. Check your connection.');
    }
  }

  Future<void> updateName(String uid, String name) async {
    try {
      await _db.collection(AppConstants.usersCollection).doc(uid).update({'name': name.trim()});
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Could not update profile.');
    }
  }
}
