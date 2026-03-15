import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/achievement_service.dart';
import '../models/match_model.dart';
import '../models/feedback_model.dart';
import '../models/player_profile_model.dart';
import '../theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final String matchId;

  const FeedbackScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool isLoading = true;
  MatchModel? match;
  List<PlayerProfileModel> players = [];
  Map<String, double> ratings = {};
  Map<String, String> comments = {};

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final AchievementService _achievementService = AchievementService();

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => isLoading = true);

    try {
      final matchData = await _firestoreService.getMatch(widget.matchId);
      if (matchData == null) return;

      setState(() => match = matchData);

      // Load player profiles
      List<PlayerProfileModel> playerList = [];
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      for (String playerId in matchData.players) {
        if (playerId != currentUser.uid) {
          final profile = await _firestoreService.getPlayerProfile(playerId);
          if (profile != null) {
            playerList.add(profile);
            ratings[playerId] = 3.0;
            comments[playerId] = '';
          }
        }
      }

      setState(() {
        players = playerList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading match: $e')),
      );
    }
  }

  Future<void> _submitFeedback() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      for (String playerId in ratings.keys) {
        final feedback = FeedbackModel(
          feedbackId: Uuid().v4(),
          matchId: widget.matchId,
          fromPlayerId: currentUser.uid,
          toPlayerId: playerId,
          rating: ratings[playerId]!,
          comments: comments[playerId]?.isEmpty ?? true ? null : comments[playerId],
          createdAt: DateTime.now(),
        );

        await _firestoreService.createFeedback(feedback);
      }

      // Update ratings for all players who received feedback
      for (String playerId in ratings.keys) {
        await _achievementService.updatePlayerRating(playerId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || match == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Match Feedback'),
          backgroundColor: AppTheme.theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Match Feedback'),
        backgroundColor: AppTheme.theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Your Teammates',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Provide feedback for all players in this match',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            ...players.map((player) {
              return Card(
                margin: EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              player.name?.substring(0, 1).toUpperCase() ?? 'P',
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              player.name ?? 'Unknown Player',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text('Rating: ${ratings[player.userId]!.toStringAsFixed(1)}'),
                      Slider(
                        value: ratings[player.userId]!,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        label: ratings[player.userId]!.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            ratings[player.userId] = value;
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Comments (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          comments[player.userId] = value;
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 10),
                  Text(
                    'Submit Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
