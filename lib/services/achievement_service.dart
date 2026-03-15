import 'package:uuid/uuid.dart';
import '../models/achievement_model.dart';
import 'firestore_service.dart';

class AchievementService {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = Uuid();

  // Check and award achievements based on player profile
  Future<void> checkAndAwardAchievements(String playerId) async {
    try {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile == null) return;

      final existingAchievements = await _firestoreService.getPlayerAchievements(playerId);
      final existingBadgeNames = existingAchievements.map((a) => a.badgeName).toSet();

      List<AchievementModel> newAchievements = [];

      // First Game Achievement
      if (profile.gamesPlayed >= 1 && !existingBadgeNames.contains('First Game')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'First Game',
          description: 'Played your first match',
          icon: '🎮',
          unlockedAt: DateTime.now(),
          category: 'games',
        ));
      }

      // 10 Games Achievement
      if (profile.gamesPlayed >= 10 && !existingBadgeNames.contains('Rookie Player')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Rookie Player',
          description: 'Played 10 matches',
          icon: '🏅',
          unlockedAt: DateTime.now(),
          category: 'games',
        ));
      }

      // 50 Games Achievement
      if (profile.gamesPlayed >= 50 && !existingBadgeNames.contains('Veteran Player')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Veteran Player',
          description: 'Played 50 matches',
          icon: '🥇',
          unlockedAt: DateTime.now(),
          category: 'games',
        ));
      }

      // 100 Games Achievement
      if (profile.gamesPlayed >= 100 && !existingBadgeNames.contains('Champion')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Champion',
          description: 'Played 100 matches',
          icon: '🏆',
          unlockedAt: DateTime.now(),
          category: 'games',
        ));
      }

      // High Rating Achievement
      if (profile.rating >= 4.5 && !existingBadgeNames.contains('Highly Rated')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Highly Rated',
          description: 'Achieved a rating of 4.5 or higher',
          icon: '⭐',
          unlockedAt: DateTime.now(),
          category: 'rating',
        ));
      }

      // Perfect Rating Achievement
      if (profile.rating >= 5.0 && !existingBadgeNames.contains('Perfect Player')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Perfect Player',
          description: 'Achieved a perfect 5.0 rating',
          icon: '💎',
          unlockedAt: DateTime.now(),
          category: 'rating',
        ));
      }

      // Skill Master Achievement
      if (profile.skillLevel >= 9.0 && !existingBadgeNames.contains('Skill Master')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Skill Master',
          description: 'Reached skill level 9.0 or higher',
          icon: '🎯',
          unlockedAt: DateTime.now(),
          category: 'skill',
        ));
      }

      // Multi-Sport Player
      if (profile.preferredSports.length >= 3 && !existingBadgeNames.contains('Multi-Sport Player')) {
        newAchievements.add(AchievementModel(
          achievementId: _uuid.v4(),
          playerId: playerId,
          badgeName: 'Multi-Sport Player',
          description: 'Play 3 or more different sports',
          icon: '🎪',
          unlockedAt: DateTime.now(),
          category: 'sports',
        ));
      }

      // Award all new achievements
      for (var achievement in newAchievements) {
        await _firestoreService.createAchievement(achievement);
      }

      // Update player profile with new achievements
      if (newAchievements.isNotEmpty) {
        final updatedAchievements = [
          ...profile.achievements,
          ...newAchievements.map((a) => a.badgeName),
        ];
        await _firestoreService.updatePlayerProfile(playerId, {
          'achievements': updatedAchievements,
        });
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Update player rating based on feedback
  Future<void> updatePlayerRating(String playerId) async {
    try {
      final feedbacks = await _firestoreService.getFeedbackForPlayer(playerId);
      
      if (feedbacks.isEmpty) return;

      double totalRating = 0.0;
      for (var feedback in feedbacks) {
        totalRating += feedback.rating;
      }

      double averageRating = totalRating / feedbacks.length;

      await _firestoreService.updatePlayerProfile(playerId, {
        'rating': averageRating,
      });
    } catch (e) {
      print('Error updating player rating: $e');
    }
  }

  // Update games played count
  Future<void> incrementGamesPlayed(String playerId) async {
    try {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile == null) return;

      await _firestoreService.updatePlayerProfile(playerId, {
        'gamesPlayed': profile.gamesPlayed + 1,
      });

      // Check for new achievements after incrementing
      await checkAndAwardAchievements(playerId);
    } catch (e) {
      print('Error incrementing games played: $e');
    }
  }

  // Record Match Result
  Future<void> recordMatchResult({required String playerId, required bool won}) async {
    try {
      final profile = await _firestoreService.getPlayerProfile(playerId);
      if (profile == null) return;

      int newGamesPlayed = profile.gamesPlayed + 1;
      int newWins = profile.totalWins + (won ? 1 : 0);
      int newLosses = profile.totalLosses + (won ? 0 : 1);

      await _firestoreService.updatePlayerProfile(playerId, {
        'gamesPlayed': newGamesPlayed,
        'totalWins': newWins,
        'totalLosses': newLosses,
      });

      // Check for new achievements after incrementing
      await checkAndAwardAchievements(playerId);

      // Extra achievement for wins (10 wins)
      if (newWins >= 10) {
        final existingAchievements = await _firestoreService.getPlayerAchievements(playerId);
        final existingBadgeNames = existingAchievements.map((a) => a.badgeName).toSet();
        if (!existingBadgeNames.contains('Decisive Winner')) {
          final achievement = AchievementModel(
            achievementId: _uuid.v4(),
            playerId: playerId,
            badgeName: 'Decisive Winner',
            description: 'Won 10 matches',
            icon: '🌟',
            unlockedAt: DateTime.now(),
            category: 'wins',
          );
          await _firestoreService.createAchievement(achievement);
          
          final updatedAchievements = [
            ...profile.achievements,
            'Decisive Winner',
          ];
          await _firestoreService.updatePlayerProfile(playerId, {
             'achievements': updatedAchievements,
          });
        }
      }
    } catch (e) {
      print('Error recording match result: $e');
    }
  }
}
