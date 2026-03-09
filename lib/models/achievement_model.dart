class AchievementModel {
  final String achievementId;
  final String playerId;
  final String badgeName;
  final String description;
  final String icon; // Icon name or emoji
  final DateTime unlockedAt;
  final String category; // 'games', 'rating', 'streak', etc.

  AchievementModel({
    required this.achievementId,
    required this.playerId,
    required this.badgeName,
    this.description = '',
    this.icon = '🏆',
    required this.unlockedAt,
    this.category = 'general',
  });

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'playerId': playerId,
      'badgeName': badgeName,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.toIso8601String(),
      'category': category,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      achievementId: map['achievementId'] ?? '',
      playerId: map['playerId'] ?? '',
      badgeName: map['badgeName'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : DateTime.now(),
      category: map['category'] ?? 'general',
    );
  }
}
