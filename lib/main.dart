import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/player_home_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/turf_home_screen.dart';
import 'screens/turf_profile_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(PlaySyncApp());
}

class PlaySyncApp extends StatelessWidget {
  const PlaySyncApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PlaySync',
      theme: AppTheme.theme,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  AuthGate({Key? key}) : super(key: key);

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const RoleSelectionScreen();
        }

        if (!user.emailVerified) {
          return const RoleSelectionScreen();
        }

        return FutureBuilder<_LaunchTarget?>(
          future: _resolveTarget(user.uid),
          builder: (context, targetSnapshot) {
            if (targetSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
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
