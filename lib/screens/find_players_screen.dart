import 'package:flutter/material.dart';

import '../constants/game_constants.dart';
import '../models/player_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'player_detail_screen.dart';

class FindPlayersScreen extends StatefulWidget {
  const FindPlayersScreen({Key? key}) : super(key: key);

  @override
  State<FindPlayersScreen> createState() => _FindPlayersScreenState();
}

class _FindPlayersScreenState extends State<FindPlayersScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();

  bool isLoading = false;
  List<PlayerProfileModel> matchingPlayers = [];
  String? selectedGame = 'Cricket';
  int minMatches = 0;

  @override
  void initState() {
    super.initState();
    _findPlayers();
  }

  Future<void> _findPlayers() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return;
      }

      final players = await _firestoreService.searchPlayers(
        usernameQuery: _usernameController.text,
        gameType: selectedGame,
        minMatches: minMatches,
        excludeUserId: currentUser.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        matchingPlayers = players;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding players: $e')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Players'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Search by name',
                    prefixIcon: Icon(Icons.person_search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _findPlayers(),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedGame,
                  decoration: InputDecoration(
                    labelText: 'Preferred Game',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: GameConstants.supportedGames.map((game) {
                    return DropdownMenuItem(
                      value: game,
                      child: Text(game),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedGame = value);
                    _findPlayers();
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: minMatches,
                  decoration: InputDecoration(
                    labelText: 'Minimum Matches',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [0, 1, 5, 10, 20, 50].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value == 0 ? 'Any experience' : '$value+ matches'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => minMatches = value);
                    _findPlayers();
                  },
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _findPlayers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : matchingPlayers.isEmpty
                    ? Center(
                        child: Text(
                          'No players matched your filters.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(15),
                        itemCount: matchingPlayers.length,
                        itemBuilder: (context, index) {
                          final player = matchingPlayers[index];
                          return _PlayerCard(
                            player: player,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerDetailScreen(playerId: player.userId),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PlayerProfileModel player;
  final VoidCallback onTap;

  const _PlayerCard({
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.theme.colorScheme.primary,
                child: Text(
                  (player.name ?? player.username ?? 'P').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name ?? 'Unknown Player',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    if ((player.name ?? '').trim().isEmpty &&
                        (player.username ?? '').trim().isNotEmpty)
                      Text(
                        player.username!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 5),
                        Text('${player.avgRating.toStringAsFixed(1)}'),
                        SizedBox(width: 15),
                        Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                        SizedBox(width: 5),
                        Text('${player.gamesPlayed} matches'),
                      ],
                    ),
                    SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      children: player.preferredSports.take(3).map((sport) {
                        return Chip(
                          label: Text(
                            sport,
                            style: TextStyle(fontSize: 10),
                          ),
                          padding: EdgeInsets.all(0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}


