import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/player_home_screen.dart';
import '../screens/turf_home_screen.dart';
import '../screens/role_selection_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // If snapshot has data, user is logged in
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          
          if (user == null) {
            return RoleSelectionScreen();
          }

          return FutureBuilder<UserModel?>(
            future: _authService.getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final String role = userSnapshot.data!.role;
                if (role == 'player') {
                  return PlayerHomeScreen();
                } else if (role == 'turfOwner') {
                  return TurfHomeScreen();
                }
              }

              // Fallback if data is missing or role is unknown
              return RoleSelectionScreen();
            },
          );
        }

        // Waiting for auth state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}