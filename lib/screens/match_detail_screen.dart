import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/matchmaking_service.dart';
import '../models/match_model.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';
import 'feedback_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _MatchDetailScreenState createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool isLoading = true;
  MatchModel? match;
  List<PlayerProfileModel> playerProfiles = [];
  Map<String, List<String>> teams = {'teamA': [], 'teamB': []};
  Map<String, dynamic>? prediction;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => isLoading = true);

    try {
      final matchData = await _firestoreService.getMatch(widget.matchId);
      if (matchData == null) {
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        match = matchData;
        teams = {
          'teamA': List.from(matchData.teamA),
          'teamB': List.from(matchData.teamB),
        };
      });

      // Load player profiles
      await _loadPlayerProfiles();

      // Calculate prediction if teams are formed
      if (matchData.teamA.isNotEmpty && matchData.teamB.isNotEmpty) {
        _calculatePrediction();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading match: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadPlayerProfiles() async {
    if (match == null) return;

    List<PlayerProfileModel> profiles = [];
    for (String playerId in match!.players) {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile != null) {
        profiles.add(profile);
      }
    }
    setState(() => playerProfiles = profiles);
  }

  void _calculatePrediction() {
    if (match == null) return;

    List<PlayerProfileModel> teamAProfiles = playerProfiles
        .where((p) => match!.teamA.contains(p.userId))
        .toList();
    List<PlayerProfileModel> teamBProfiles = playerProfiles
        .where((p) => match!.teamB.contains(p.userId))
        .toList();

    if (teamAProfiles.isNotEmpty && teamBProfiles.isNotEmpty) {
      setState(() {
        prediction = _matchmakingService.predictMatchOutcome(
          teamAProfiles,
          teamBProfiles,
        );
      });
    }
  }

  Future<void> _joinMatch() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null || match == null) return;

      if (match!.players.contains(currentUser.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already in this match')),
        );
        return;
      }

      if (match!.players.length >= match!.maxPlayers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Match is full')),
        );
        return;
      }

      List<String> updatedPlayers = List.from(match!.players);
      updatedPlayers.add(currentUser.uid);

      await _firestoreService.updateMatch(widget.matchId, {
        'players': updatedPlayers,
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining match: $e')),
      );
    }
  }

  Future<void> _formTeams() async {
    if (match == null || playerProfiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need at least 2 players to form teams')),
      );
      return;
    }

    try {
      final balancedTeams = _matchmakingService.formBalancedTeams(playerProfiles);

      await _firestoreService.updateMatch(widget.matchId, {
        'teamA': balancedTeams['teamA'],
        'teamB': balancedTeams['teamB'],
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error forming teams: $e')),
      );
    }
  }

  Future<void> _performToss() async {
    if (match == null) return;

    final random = DateTime.now().millisecondsSinceEpoch % 2;
    final winner = random == 0 ? 'teamA' : 'teamB';
    final choice = ['bat', 'bowl'][DateTime.now().millisecondsSinceEpoch % 2];

    try {
      await _firestoreService.updateMatch(widget.matchId, {
        'tossResult': {
          'winner': winner,
          'choice': choice,
        },
        'matchStatus': 'active',
      });

      _loadMatch();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing toss: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || match == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Match Details'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = _authService.currentUser;
    final isPlayer = currentUser != null && match!.players.contains(currentUser.uid);
    final isCreator = currentUser != null && match!.createdBy == currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (match!.matchStatus == 'completed' && isPlayer)
            IconButton(
              icon: Icon(Icons.feedback),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(matchId: match!.matchId),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match!.gameType,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(match!.matchStatus).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            match!.matchStatus.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(match!.matchStatus),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    _InfoRow(Icons.location_on, match!.location),
                    if (match!.scheduledTime != null)
                      _InfoRow(
                        Icons.calendar_today,
                        '${match!.scheduledTime!.day}/${match!.scheduledTime!.month}/${match!.scheduledTime!.year} ${match!.scheduledTime!.hour}:${match!.scheduledTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    _InfoRow(Icons.people, '${match!.players.length}/${match!.maxPlayers} players'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Join/Form Teams Buttons
            if (!isPlayer && match!.players.length < match!.maxPlayers)
              ElevatedButton(
                onPressed: _joinMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 10),
                    Text('Join Match', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),

            if (isCreator && match!.teamA.isEmpty && match!.players.length >= 2)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: ElevatedButton(
                  onPressed: _formTeams,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group),
                      SizedBox(width: 10),
                      Text('Form Balanced Teams', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

            // Teams Section
            if (match!.teamA.isNotEmpty || match!.teamB.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Teams',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _TeamCard(
                      title: 'Team A',
                      playerIds: match!.teamA,
                      profiles: playerProfiles,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _TeamCard(
                      title: 'Team B',
                      playerIds: match!.teamB,
                      profiles: playerProfiles,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // Toss Section
              if (match!.tossResult == null && isCreator && match!.matchStatus == 'pending')
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _performToss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino),
                        SizedBox(width: 10),
                        Text('Perform Toss', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),

              if (match!.tossResult != null) ...[
                SizedBox(height: 20),
                Card(
                  color: Colors.amber.withOpacity(0.2),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text(
                          'Toss Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '${match!.tossResult!['winner'] == 'teamA' ? 'Team A' : 'Team B'} won the toss and chose to ${match!.tossResult!['choice']}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Prediction
              if (prediction != null) ...[
                SizedBox(height: 20),
                Card(
                  color: Colors.purple.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match Prediction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Team A Win Probability: ${(prediction!['teamAWinProbability'] * 100).toStringAsFixed(1)}%',
                        ),
                        Text(
                          'Team B Win Probability: ${(prediction!['teamBWinProbability'] * 100).toStringAsFixed(1)}%',
                        ),
                        SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: prediction!['teamAWinProbability'],
                          backgroundColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // Players List
            SizedBox(height: 20),
            Text(
              'Players (${match!.players.length})',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            ...playerProfiles.map((profile) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(profile.name?.substring(0, 1).toUpperCase() ?? 'P'),
                ),
                title: Text(profile.name ?? 'Unknown'),
                subtitle: Text('Rating: ${profile.rating.toStringAsFixed(1)}'),
                trailing: Icon(Icons.star, color: Colors.amber),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String title;
  final List<String> playerIds;
  final List<PlayerProfileModel> profiles;
  final Color color;

  const _TeamCard({
    required this.title,
    required this.playerIds,
    required this.profiles,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final teamProfiles = profiles.where((p) => playerIds.contains(p.userId)).toList();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 10),
            ...teamProfiles.map((profile) {
              return Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '• ${profile.name ?? 'Unknown'}',
                  style: TextStyle(fontSize: 14),
                ),
              );
            }),
            if (teamProfiles.isEmpty)
              Text(
                'No players yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
