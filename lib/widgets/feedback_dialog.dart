import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/feedback_model.dart';
import '../models/player_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class FeedbackDialog extends StatefulWidget {
  final String matchId;
  final String gameType;
  final List<PlayerProfileModel> participants;

  const FeedbackDialog({
    required this.matchId,
    required this.gameType,
    required this.participants,
  });

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  Map<String, double> ratings = {};
  Map<String, String> comments = {};
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final currentUserId = _authService.currentUser?.uid;
    for (var p in widget.participants) {
      if (p.userId != currentUserId) {
        ratings[p.userId] = 5.0;
        comments[p.userId] = '';
      }
    }
  }

  Future<void> _submitAllFeedback() async {
    setState(() => isSubmitting = true);
    try {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId == null) return;

      for (var entry in ratings.entries) {
        final feedback = FeedbackModel(
          feedbackId: const Uuid().v4(),
          matchId: widget.matchId,
          fromUserId: currentUserId,
          toUserId: entry.key,
          rating: entry.value,
          comment: comments[entry.key],
          gameType: widget.gameType,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createFeedback(feedback);
        await _firestoreService.refreshPlayerRating(entry.key);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thank you for your feedback!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting feedback: $e')),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final otherParticipants = widget.participants.where((p) => p.userId != currentUserId).toList();

    return AlertDialog(
      title: Text('Rate Participants'),
      content: Container(
        width: double.maxFinite,
        child: otherParticipants.isEmpty 
          ? Center(child: Text('No other players to rate.'))
          : ListView.builder(
            shrinkWrap: true,
            itemCount: otherParticipants.length,
            itemBuilder: (context, index) {
              final player = otherParticipants[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name ?? 'Unknown Player',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Text('Rating: '),
                      Expanded(
                        child: Slider(
                          value: ratings[player.userId] ?? 5.0,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: (ratings[player.userId] ?? 5.0).toString(),
                          onChanged: (val) {
                            setState(() => ratings[player.userId] = val);
                          },
                        ),
                      ),
                      Text((ratings[player.userId] ?? 5.0).toStringAsFixed(1)),
                    ],
                  ),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => comments[player.userId] = val,
                  ),
                  Divider(height: 30),
                ],
              );
            },
          ),
      ),
      actions: [
        if (!isSubmitting)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip'),
          ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitAllFeedback,
          child: isSubmitting 
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text('Submit All'),
        ),
      ],
    );
  }
}

