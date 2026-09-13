import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `users/{uid}` document:
/// {name, email, online, createdAt}
class AppUser {
  final String uid;
  final String name;
  final String email;
  final bool online;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.online,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      online: (data['online'] ?? false) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'online': online,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// First letter for the avatar placeholder.
  String get initial => name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
}
