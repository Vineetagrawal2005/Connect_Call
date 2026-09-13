import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/user_service.dart';
import 'services/zego_service.dart';

/// Global navigator key — required by ZegoUIKitPrebuiltCallInvitationService
/// so the incoming-call screen can appear over any route.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lets ZEGOCLOUD show the Accept/Decline incoming-call screen anywhere.
  ZegoService.setNavigatorKey(navigatorKey);

  // Restore calling session for an already-signed-in user (cold start).
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      await ZegoService.uninit();
    } else {
      try {
        String name = user.displayName ?? '';
        if (name.isEmpty) {
          final profile = await UserService().getUser(user.uid);
          if (profile != null && profile.name.isNotEmpty) name = profile.name;
        }
        await ZegoService.init(
          userId: user.uid,
          userName: name.isEmpty ? (user.email ?? user.uid) : name,
        );
      } catch (_) {}
    }
  });

  runApp(const ConnectCallApp());
}

class ConnectCallApp extends StatelessWidget {
  const ConnectCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'ConnectCall',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: navigatorKey,
        initialRoute: AppConstants.routeSplash,
        routes: {
          AppConstants.routeSplash: (_) => const SplashScreen(),
          AppConstants.routeLogin: (_) => const LoginScreen(),
          AppConstants.routeRegister: (_) => const RegisterScreen(),
          AppConstants.routeHome: (_) => const HomeScreen(),
        },
      ),
    );
  }
}
