import 'package:flutter/material.dart';

import '../models/player_profile_model.dart';

class PlayerStatsWidget extends StatelessWidget {
  final PlayerProfileModel profile;

  const PlayerStatsWidget({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatItem('Matches', profile.gamesPlayed.toString(), Icons.sports_soccer),
      _StatItem('Wins', profile.totalWins.toString(), Icons.emoji_events),
      _StatItem(
        'Win %',
        '${profile.winPercentage.toStringAsFixed(1)}%',
        Icons.pie_chart,
      ),
      _StatItem(
        'Ratings',
        profile.totalRatings.toString(),
        Icons.reviews_outlined,
      ),
      _StatItem(
        'Avg Rating',
        profile.avgRating.toStringAsFixed(1),
        Icons.star,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((item) {
        return SizedBox(
          width: 156,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(item.icon, color: Colors.blueGrey[700], size: 28),
                  SizedBox(height: 10),
                  Text(
                    item.value,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);
}
