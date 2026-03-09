import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String playerId;

  const PlayerDetailScreen({Key? key, required this.playerId}) : super(key: key);

  @override
  _PlayerDetailScreenState createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  bool isLoading = true;
  PlayerProfileModel? profile;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final profileData = await _firestoreService.getPlayerProfile(widget.playerId);
      setState(() {
        profile = profileData;
        isLoading = false;
      });
    } catch (e) {
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
          title: Text('Player Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Player Profile'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text('Player not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Player Profile'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),

            // Stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.star, size: 40, color: Colors.amber),
                          SizedBox(height: 10),
                          Text(
                            profile!.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Rating'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.sports_soccer, size: 40, color: Colors.blue),
                          SizedBox(height: 10),
                          Text(
                            profile!.gamesPlayed.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Games'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

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
                          backgroundColor: AppTheme.theme.colorScheme.primary.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
