import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../models/player_profile_model.dart';
import 'player_stats_widget.dart';

class PlayerProfileContent extends StatelessWidget {
  final PlayerProfileModel profile;
  final List<FeedbackModel> feedbackList;
  final Map<String, int> gameCounts;
  final Widget? footer;

  const PlayerProfileContent({
    Key? key,
    required this.profile,
    required this.feedbackList,
    this.gameCounts = const {},
    this.footer,
  }) : super(key: key);

  String get _avatarLetter {
    final source = (profile.name ?? '').trim().isNotEmpty
        ? profile.name!.trim()
        : (profile.username ?? '').trim().isNotEmpty
            ? profile.username!.trim()
            : 'P';
    return source.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final comments = feedbackList
        .where((item) => (item.comment ?? '').trim().isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Text(
                    _avatarLetter,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  profile.name ?? 'Unknown Player',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                if ((profile.name ?? '').trim().isEmpty &&
                    (profile.username ?? '').trim().isNotEmpty)
                  Text(
                    profile.username!,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Player Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 14),
          PlayerStatsWidget(profile: profile),
          SizedBox(height: 24),
          _SectionCard(
            title: 'Games Played',
            child: gameCounts.isEmpty
                ? Text('No completed games yet.')
                : Column(
                    children: gameCounts.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${entry.value} matches',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          SizedBox(height: 16),
          _SectionCard(
            title: 'Preferred Games',
            child: profile.preferredSports.isEmpty
                ? Text('No preferred games added yet.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.preferredSports.map((game) {
                      return Chip(label: Text(game));
                    }).toList(),
                  ),
          ),
          SizedBox(height: 16),
          _SectionCard(
            title: 'Feedback Comments',
            child: comments.isEmpty
                ? Text('No feedback received yet.')
                : Column(
                    children: comments.map((feedback) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 6),
                                Text(
                                  feedback.rating.toStringAsFixed(1),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (feedback.gameType.isNotEmpty) ...[
                                  SizedBox(width: 8),
                                  Text(
                                    feedback.gameType,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(feedback.comment!.trim()),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          if (footer != null) ...[
            SizedBox(height: 24),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}


