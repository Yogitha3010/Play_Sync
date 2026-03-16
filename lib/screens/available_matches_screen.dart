import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'match_detail_screen.dart';

class AvailableMatchesScreen extends StatefulWidget {
  @override
  _AvailableMatchesScreenState createState() => _AvailableMatchesScreenState();
}

class _AvailableMatchesScreenState extends State<AvailableMatchesScreen> {
  bool isLoading = true;
  List<MatchModel> availableMatches = [];
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadAvailableMatches();
  }

  Future<void> _loadAvailableMatches() async {
    setState(() => isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          availableMatches = [];
          isLoading = false;
        });
        return;
      }

      final pendingMatches = await _firestoreService.getMatchesByStatus('pending');
      final userTeams = await _firestoreService.getTeamsForPlayer(currentUser.uid);
      final userTeamIds = userTeams.map((team) => team.teamId).toSet();

      final now = DateTime.now();
      final filteredMatches = pendingMatches.where((match) {
        final isAlreadyJoined = match.players.contains(currentUser.uid);
        final isFull = match.players.length >= match.maxPlayers;
        final isExpired =
            match.scheduledTime != null && !match.scheduledTime!.isAfter(now);
        final isVisibleToUser = match.visibility != 'team' ||
            (match.teamId != null && userTeamIds.contains(match.teamId));

        return isVisibleToUser && !isAlreadyJoined && !isFull && !isExpired;
      }).toList()
        ..sort((a, b) {
          final aTime = a.scheduledTime ?? a.createdAt;
          final bTime = b.scheduledTime ?? b.createdAt;
          return aTime.compareTo(bTime);
        });

      if (!mounted) return;
      setState(() {
        availableMatches = filteredMatches;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading matches: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Matches'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAvailableMatches,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : availableMatches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No available matches found.\nCreate your own match to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: availableMatches.length,
                  itemBuilder: (context, index) {
                    final match = availableMatches[index];
                    return _buildMatchCard(context, match);
                  },
                ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchModel match) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(matchId: match.matchId),
            ),
          ).then((_) {
            _loadAvailableMatches(); // Reload when returning in case they joined
          });
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    match.gameType,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (match.visibility == 'team'
                              ? Colors.teal
                              : Colors.orange)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      match.visibility == 'team' ? 'TEAM MATCH' : 'OPEN TO JOIN',
                      style: TextStyle(
                        color: match.visibility == 'team'
                            ? Colors.teal[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '${match.players.length}/${match.maxPlayers} Players',
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (match.scheduledTime != null)
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          _formatScheduledTime(match.scheduledTime!),
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatScheduledTime(DateTime scheduledTime) {
    final day = scheduledTime.day.toString().padLeft(2, '0');
    final month = scheduledTime.month.toString().padLeft(2, '0');
    final year = scheduledTime.year.toString();
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
