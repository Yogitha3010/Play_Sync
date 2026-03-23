import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/available_match_card.dart';
import 'match_detail_screen.dart';

class MatchesByGameScreen extends StatefulWidget {
  final String selectedGame;

  const MatchesByGameScreen({
    Key? key,
    required this.selectedGame,
  }) : super(key: key);

  @override
  State<MatchesByGameScreen> createState() => _MatchesByGameScreenState();
}

class _MatchesByGameScreenState extends State<MatchesByGameScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool isLoading = true;
  List<MatchModel> availableMatches = [];

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
        setState(() {
          availableMatches = [];
          isLoading = false;
        });
        return;
      }

      final pendingMatches = await _firestoreService.getMatchesByGameAndStatus(
        gameType: widget.selectedGame,
        status: 'pending',
      );
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

      if (!mounted) {
        return;
      }
      setState(() {
        availableMatches = filteredMatches;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load ${widget.selectedGame} matches. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedGame} Matches'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : availableMatches.isEmpty
              ? Center(
                  child: Text(
                    'No available ${widget.selectedGame} matches right now.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAvailableMatches,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: availableMatches.length,
                    itemBuilder: (context, index) {
                      final match = availableMatches[index];
                      return AvailableMatchCard(
                        match: match,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchDetailScreen(matchId: match.matchId),
                            ),
                          ).then((_) => _loadAvailableMatches());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
