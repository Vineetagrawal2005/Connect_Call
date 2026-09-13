import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/zego_service.dart';

/// ChangeNotifier wrapping AuthService (the single Provider in the app).
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  AuthProvider({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? get user => _authService.currentUser;
  bool get isLoggedIn => user != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<User?> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      final user = await _authService.signIn(email: email, password: password);
      await _initCalling(user);
      return user;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signUp({required String name, required String email, required String password}) async {
    _setLoading(true);
    try {
      final user = await _authService.signUp(name: name, email: email, password: password);
      await _initCalling(user);
      return user;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh ZEGOCLOUD session for an already-signed-in user (splash path).
  Future<void> initCallingForCurrentUser() async {
    final current = _authService.currentUser;
    if (current == null) return;
    await _initCalling(current);
    notifyListeners();
  }

  Future<void> _initCalling(User user) async {
    try {
      String name = user.displayName ?? '';
      if (name.isEmpty) {
        final profile = await _userService.getUser(user.uid);
        if (profile != null && profile.name.isNotEmpty) name = profile.name;
      }
      if (name.isEmpty) name = user.email ?? user.uid;
      await ZegoService.init(userId: user.uid, userName: name);
    } catch (_) {
      // Calling init must never block login.
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      try {
        await ZegoService.uninit();
      } catch (_) {}
      await _authService.signOut();
    } finally {
      _setLoading(false);
    }
  }
}
