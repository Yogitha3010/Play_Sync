import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/animated_splash_screen.dart';
import 'screens/player_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/turf_home_screen.dart';
import 'screens/turf_profile_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/push_notification_service.dart';
import 'services/local_notification_service.dart';
import 'services/firestore_notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await PushNotificationService.instance.initialize(
    navigatorKey: appNavigatorKey,
  );
  await LocalNotificationService.instance.initialize();
  runApp(const PlaySyncApp());
}

class PlaySyncApp extends StatelessWidget {
  const PlaySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PlaySync',
      theme: AppTheme.theme,
      home: const AnimatedSplashScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          FirestoreNotificationService.instance.stopListening();
          return const RoleSelectionScreen();
        }

        if (!user.emailVerified) {
          FirestoreNotificationService.instance.stopListening();
          return const RoleSelectionScreen();
        }

        // Start listening to Firestore real-time notifications
        FirestoreNotificationService.instance.startListening(user.uid);

        return FutureBuilder<_LaunchTarget?>(
          future: _resolveTarget(user.uid),
          builder: (context, targetSnapshot) {
            if (targetSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final target = targetSnapshot.data;
            if (target == null) {
              return const RoleSelectionScreen();
            }

            return target.screen;
          },
        );
      },
    );
  }

  Future<_LaunchTarget?> _resolveTarget(String userId) async {
    final userData = await _authService.getUserData(userId);
    if (userData == null) {
      return null;
    }

    if (userData.role == 'turfOwner') {
      final turfs = await _firestoreService.getTurfsByOwner(userId);
      if (!userData.profileCompleted || turfs.isEmpty) {
        return _LaunchTarget(
          userData,
          TurfProfileSetupScreen(ownerId: userId),
        );
      }
      return _LaunchTarget(userData, TurfHomeScreen());
    }

    return _LaunchTarget(userData, PlayerHomeScreen());
  }
}

class _LaunchTarget {
  final UserModel user;
  final Widget screen;

  const _LaunchTarget(this.user, this.screen);
}
