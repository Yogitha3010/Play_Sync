import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../services/auth_service.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';
import 'player_detail_screen.dart';

class FindPlayersScreen extends StatefulWidget {
  @override
  _FindPlayersScreenState createState() => _FindPlayersScreenState();
}

class _FindPlayersScreenState extends State<FindPlayersScreen> {
  bool isLoading = false;
  List<PlayerProfileModel> matchingPlayers = [];
  String selectedGame = 'Cricket';
  final List<String> games = ['Cricket', 'Badminton', 'Pickleball', 'Football', 'Basketball', 'Tennis', 'Volleyball'];

  final MatchmakingService _matchmakingService = MatchmakingService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _findPlayers();
  }

  Future<void> _findPlayers() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final players = await _matchmakingService.findMatchingPlayers(
        currentPlayerId: currentUser.uid,
        gameType: selectedGame,
        maxResults: 20,
      );

      setState(() {
        matchingPlayers = players;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding players: $e')),
      );
    }
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
          // Filters
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.grey[100],
            child: DropdownButtonFormField<String>(
              value: selectedGame,
              decoration: InputDecoration(
                labelText: 'Sport',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: games.map((game) {
                return DropdownMenuItem(
                  value: game,
                  child: Text(game),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedGame = value);
                  _findPlayers();
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : matchingPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              'No matching players found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _findPlayers,
                              child: Text('Search Again'),
                            ),
                          ],
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
                                  builder: (_) => PlayerDetailScreen(playerId: player.userId),
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
                  player.name?.substring(0, 1).toUpperCase() ?? 'P',
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
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 5),
                        Text('${player.rating.toStringAsFixed(1)}'),
                        SizedBox(width: 15),
                        Icon(Icons.sports_soccer, size: 16, color: Colors.grey),
                        SizedBox(width: 5),
                        Text('${player.gamesPlayed} games'),
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
