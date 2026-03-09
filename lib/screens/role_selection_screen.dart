import 'package:flutter/material.dart';
import '../auth/widgets/role_card.dart';
import 'player_auth_screen.dart';
import 'turf_auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PlaySync",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Sync Your Game. Find Your Team.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 50),

            /// Player Login
            RoleCard(
              title: "Continue as Player",
              icon: Icons.sports_cricket,
              screen: PlayerLoginScreen(),
            ),

            SizedBox(height: 20),

            /// Turf Owner Login
            RoleCard(
              title: "Continue as Turf Owner",
              icon: Icons.stadium,
              screen: TurfLoginScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
