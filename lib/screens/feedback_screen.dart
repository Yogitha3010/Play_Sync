import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/feedback_model.dart';
import '../models/match_model.dart';
import '../models/player_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  final String matchId;

  const FeedbackScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  bool alreadySubmitted = false;
  MatchModel? match;
  List<PlayerProfileModel> players = [];
  Map<String, int> ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    setState(() => isLoading = true);

    try {
      final matchData = await _firestoreService.getMatch(widget.matchId);
      final currentUser = _authService.currentUser;
      if (matchData == null || currentUser == null) {
        return;
      }

      final hasSubmitted = await _firestoreService.hasSubmittedFeedback(
        matchId: widget.matchId,
        fromUserId: currentUser.uid,
      );

      if (hasSubmitted) {
        if (!mounted) {
          return;
        }
        setState(() {
          match = matchData;
          players = [];
          alreadySubmitted = true;
          isLoading = false;
        });
        return;
      }

      final playerList = <PlayerProfileModel>[];
      for (final playerId in matchData.players) {
        if (playerId == currentUser.uid) {
          continue;
        }
        final profile = await _firestoreService.getPlayerProfile(playerId);
        if (profile != null) {
          playerList.add(profile);
          ratings[playerId] = 5;
          _commentControllers[playerId] = TextEditingController();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        match = matchData;
        players = playerList;
        alreadySubmitted = false;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feedback form: $e')),
      );
    }
  }

  Future<void> _submitFeedback() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || match == null || isSubmitting) {
      return;
    }

    setState(() => isSubmitting = true);
    try {
      for (final player in players) {
        final feedback = FeedbackModel(
          feedbackId: Uuid().v4(),
          fromUserId: currentUser.uid,
          toUserId: player.userId,
          matchId: widget.matchId,
          rating: (ratings[player.userId] ?? 5).toDouble(),
          comment: _commentControllers[player.userId]?.text.trim().isEmpty ?? true
              ? null
              : _commentControllers[player.userId]!.text.trim(),
          gameType: match!.gameType,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createFeedback(feedback);
        await _firestoreService.refreshPlayerRating(player.userId);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
      body: alreadySubmitted
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 60, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Feedback already submitted',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Your ratings and comments have already been saved for this match.',
                      style: TextStyle(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : players.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No players to review',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Feedback is available when there are other players in this completed match.',
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Players',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Review every player from this match except yourself.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ...players.map((player) {
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name ?? player.username ?? 'Player',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      if ((player.name ?? '').trim().isEmpty &&
                          (player.username ?? '').trim().isNotEmpty)
                        Text(
                          player.username!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: List.generate(5, (index) {
                          final starValue = index + 1;
                          final selected = (ratings[player.userId] ?? 5) >= starValue;
                          return IconButton(
                            onPressed: () {
                              setState(() => ratings[player.userId] = starValue);
                            },
                            icon: Icon(
                              selected ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        controller: _commentControllers[player.userId],
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Comment',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isSubmitting ? 'Submitting...' : 'Submit Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


