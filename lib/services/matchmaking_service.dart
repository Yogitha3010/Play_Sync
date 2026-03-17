import 'dart:math';
import '../models/player_profile_model.dart';
import '../models/match_model.dart';
import 'firestore_service.dart';
import 'firebase_service.dart';

class MatchmakingService {
  final FirestoreService _firestoreService = FirestoreService();

  // Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Find matching players based on skill level, location, and preferences
  Future<List<PlayerProfileModel>> findMatchingPlayers({
    required String currentPlayerId,
    required String gameType,
    required int maxResults,
    double? maxDistance, // in km
    double? skillLevelTolerance,
  }) async {
    try {
      // Get current player profile
      final currentPlayer =
          await _firestoreService.getPlayerProfile(currentPlayerId);
      if (currentPlayer == null) {
        return [];
      }

      // Get all player profiles
      final allPlayersSnapshot = await FirebaseService
          .playerProfilesCollection
          .where('preferredSports', arrayContains: gameType)
          .get();

      List<PlayerProfileModel> allPlayers = allPlayersSnapshot.docs
          .map((doc) => PlayerProfileModel.fromMap(
              doc.data() as Map<String, dynamic>))
          .where((player) => player.userId != currentPlayerId)
          .toList();

      // Calculate compatibility scores
      List<Map<String, dynamic>> scoredPlayers = [];

      for (var player in allPlayers) {
        double compatibilityScore = 0.0;

        // Skill level compatibility (40% weight)
        double skillDiff = (currentPlayer.skillLevel - player.skillLevel).abs();
        double skillTolerance = skillLevelTolerance ?? 2.0;
        double skillScore = 1.0 - (skillDiff / skillTolerance).clamp(0.0, 1.0);
        compatibilityScore += skillScore * 0.4;

        // Location proximity (30% weight) when a distance filter is provided
        if (maxDistance != null &&
            currentPlayer.location.isNotEmpty &&
            player.location.isNotEmpty) {
          double distance = calculateDistance(
            currentPlayer.location['latitude'] ?? 0.0,
            currentPlayer.location['longitude'] ?? 0.0,
            player.location['latitude'] ?? 0.0,
            player.location['longitude'] ?? 0.0,
          );

          if (distance <= maxDistance) {
            double locationScore = 1.0 - (distance / maxDistance).clamp(0.0, 1.0);
            compatibilityScore += locationScore * 0.3;
          } else {
            continue; // Skip players outside max distance
          }
        } else {
          // If no distance filter is provided, or location is unavailable, give neutral score
          compatibilityScore += 0.15;
        }

        // Rating compatibility (20% weight)
        double ratingDiff = (currentPlayer.rating - player.rating).abs();
        double ratingScore = 1.0 - (ratingDiff / 5.0).clamp(0.0, 1.0);
        compatibilityScore += ratingScore * 0.2;

        // Experience compatibility (10% weight)
        int gamesDiff = (currentPlayer.gamesPlayed - player.gamesPlayed).abs();
        double experienceScore = 1.0 - (gamesDiff / 50.0).clamp(0.0, 1.0);
        compatibilityScore += experienceScore * 0.1;

        scoredPlayers.add({
          'player': player,
          'score': compatibilityScore,
          'distance': currentPlayer.location.isNotEmpty &&
                  player.location.isNotEmpty
              ? calculateDistance(
                  currentPlayer.location['latitude'] ?? 0.0,
                  currentPlayer.location['longitude'] ?? 0.0,
                  player.location['latitude'] ?? 0.0,
                  player.location['longitude'] ?? 0.0,
                )
              : double.infinity,
        });
      }

      // Sort by compatibility score
      scoredPlayers.sort((a, b) => b['score'].compareTo(a['score']));

      // Return top matches
      return scoredPlayers
          .take(maxResults)
          .map((item) => item['player'] as PlayerProfileModel)
          .toList();
    } catch (e) {
      print('Error in matchmaking: $e');
      return [];
    }
  }

  // Form balanced teams from a list of players
  Map<String, List<String>> formBalancedTeams(
      List<PlayerProfileModel> players) {
    if (players.length < 2) {
      return {'teamA': [], 'teamB': []};
    }

    // Sort players by skill level
    List<PlayerProfileModel> sortedPlayers = List.from(players);
    sortedPlayers.sort((a, b) => b.skillLevel.compareTo(a.skillLevel));

    List<String> teamA = [];
    List<String> teamB = [];
    double teamASkill = 0.0;
    double teamBSkill = 0.0;

    // Distribute players alternately to balance teams
    for (int i = 0; i < sortedPlayers.length; i++) {
      if (i % 2 == 0) {
        teamA.add(sortedPlayers[i].userId);
        teamASkill += sortedPlayers[i].skillLevel;
      } else {
        teamB.add(sortedPlayers[i].userId);
        teamBSkill += sortedPlayers[i].skillLevel;
      }
    }

    // If teams are unbalanced, swap a player
    if ((teamASkill - teamBSkill).abs() > 2.0 && sortedPlayers.length > 2) {
      // Swap last player from stronger team to weaker team
      if (teamASkill > teamBSkill && teamA.length > 1) {
        String lastPlayer = teamA.removeLast();
        teamB.add(lastPlayer);
      } else if (teamBSkill > teamASkill && teamB.length > 1) {
        String lastPlayer = teamB.removeLast();
        teamA.add(lastPlayer);
      }
    }

    return {'teamA': teamA, 'teamB': teamB};
  }

  // Get match predictions based on team composition
  Map<String, dynamic> predictMatchOutcome(
      List<PlayerProfileModel> teamA, List<PlayerProfileModel> teamB) {
    double teamASkill = teamA.fold(0.0, (sum, p) => sum + p.skillLevel) /
        teamA.length;
    double teamBSkill = teamB.fold(0.0, (sum, p) => sum + p.skillLevel) /
        teamB.length;

    double teamARating = teamA.fold(0.0, (sum, p) => sum + p.rating) /
        teamA.length;
    double teamBRating = teamB.fold(0.0, (sum, p) => sum + p.rating) /
        teamB.length;

    double teamAWinProbability =
        (teamASkill + teamARating) / (teamASkill + teamARating + teamBSkill + teamBRating);

    return {
      'teamAWinProbability': teamAWinProbability,
      'teamBWinProbability': 1.0 - teamAWinProbability,
      'predictedWinner': teamAWinProbability > 0.5 ? 'teamA' : 'teamB',
      'confidence': (teamAWinProbability - 0.5).abs() * 2, // 0 to 1
    };
  }
}
