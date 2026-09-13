import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

/// Req 1: checks FirebaseAuth.instance.currentUser and routes to Login/Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Brief pause so the splash is visible; Firebase was inited in main().
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Existing session: restore the calling service, then go home.
      try {
        await context.read<AuthProvider>().initCallingForCurrentUser();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_call, size: 72, color: Color(0xFF1A73E8)),
            SizedBox(height: 16),
            Text('ConnectCall', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
