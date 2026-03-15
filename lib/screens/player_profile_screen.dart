import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';
import 'edit_player_profile_screen.dart';

class PlayerProfileScreen extends StatefulWidget {
  @override
  _PlayerProfileScreenState createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool isLoading = true;
  PlayerProfileModel? profile;

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
      if (currentUser == null) return;

      final profileData = await _firestoreService.getPlayerProfile(
        currentUser.uid,
      );
      setState(() {
        profile = profileData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
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
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPlayerProfileScreen(profile: profile!),
                ),
              ).then((_) => _loadProfile());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.theme.colorScheme.primary,
              child: Text(
                profile!.name?.substring(0, 1).toUpperCase() ?? 'P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              profile!.name ?? 'Unknown Player',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Rating',
                    value: profile!.rating.toStringAsFixed(1),
                    icon: Icons.thumb_up,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Games Played',
                    value: profile!.gamesPlayed.toString(),
                    icon: Icons.sports_soccer,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    title: 'Achievements',
                    value: profile!.achievements.length.toString(),
                    icon: Icons.star,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Wins',
                    value: profile!.totalWins.toString(),
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    title: 'Win %',
                    value: '${profile!.winPercentage.toStringAsFixed(1)}%',
                    icon: Icons.pie_chart,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Preferred Sports
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Sports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profile!.preferredSports.map((sport) {
                        return Chip(
                          label: Text(sport),
                          backgroundColor: AppTheme.theme.colorScheme.primary
                              .withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Location
            if (profile!.locationAddress != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: AppTheme.theme.colorScheme.primary,
                  ),
                  title: Text('Location'),
                  subtitle: Text(profile!.locationAddress!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
