import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../models/match_model.dart';
import '../models/player_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player_profile_content.dart';
import 'edit_player_profile_screen.dart';
import 'role_selection_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool isLoading = true;
  PlayerProfileModel? profile;
  List<FeedbackModel> feedbackList = [];
  List<MatchModel> playerMatches = [];
  Map<String, int> gameCounts = {};

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      final profileData = await _firestoreService.getPlayerProfile(currentUser.uid);
      final feedbackData = await _firestoreService.getFeedbackForPlayer(
        currentUser.uid,
      );
      final matches = await _firestoreService.getPlayerMatches(currentUser.uid);

      final counts = <String, int>{};
      for (final match in matches) {
        counts.update(match.gameType, (value) => value + 1, ifAbsent: () => 1);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        profile = profileData;
        feedbackList = feedbackData;
        playerMatches = matches;
        gameCounts = Map.fromEntries(
          counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PlayerProfileContent(
        profile: profile!,
        feedbackList: feedbackList,
        gameCounts: gameCounts,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileSummaryTile(
              label: 'Total Matches Played',
              value: playerMatches.length.toString(),
              icon: Icons.sports_score,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPlayerProfileScreen(profile: profile!),
                  ),
                ).then((_) => _loadProfile());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.theme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Edit Profile'),
            ),
            SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await _authService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
