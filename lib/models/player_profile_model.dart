class PlayerProfileModel {
  final String userId;
  final String? name;
  final double skillLevel; // 0.0 to 10.0
  final int gamesPlayed;
  final int totalWins;
  final int totalLosses;
  final double rating; // Average rating from feedback
  final List<String> preferredSports;
  final Map<String, double> location; // {latitude, longitude}
  final String? locationAddress;
  final List<String> achievements;
  final Map<String, dynamic> matchHistory;
  final DateTime? lastUpdated;

  PlayerProfileModel({
    required this.userId,
    this.name,
    this.skillLevel = 5.0,
    this.gamesPlayed = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.rating = 0.0,
    this.preferredSports = const [],
    this.location = const {},
    this.locationAddress,
    this.achievements = const [],
    this.matchHistory = const {},
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'skillLevel': skillLevel,
      'gamesPlayed': gamesPlayed,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'rating': rating,
      'preferredSports': preferredSports,
      'location': location,
      'locationAddress': locationAddress,
      'achievements': achievements,
      'matchHistory': matchHistory,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PlayerProfileModel.fromMap(Map<String, dynamic> map) {
    return PlayerProfileModel(
      userId: map['userId'] ?? '',
      name: map['name'],
      skillLevel: (map['skillLevel'] ?? 5.0).toDouble(),
      gamesPlayed: map['gamesPlayed'] ?? 0,
      totalWins: map['totalWins'] ?? 0,
      totalLosses: map['totalLosses'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      preferredSports: List<String>.from(map['preferredSports'] ?? []),
      location: Map<String, double>.from(map['location'] ?? {}),
      locationAddress: map['locationAddress'],
      achievements: List<String>.from(map['achievements'] ?? []),
      matchHistory: Map<String, dynamic>.from(map['matchHistory'] ?? {}),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }

  PlayerProfileModel copyWith({
    String? userId,
    String? name,
    double? skillLevel,
    int? gamesPlayed,
    int? totalWins,
    int? totalLosses,
    double? rating,
    List<String>? preferredSports,
    Map<String, double>? location,
    String? locationAddress,
    List<String>? achievements,
    Map<String, dynamic>? matchHistory,
    DateTime? lastUpdated,
  }) {
    return PlayerProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      skillLevel: skillLevel ?? this.skillLevel,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      rating: rating ?? this.rating,
      preferredSports: preferredSports ?? this.preferredSports,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      achievements: achievements ?? this.achievements,
      matchHistory: matchHistory ?? this.matchHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  double get winPercentage {
    if (gamesPlayed == 0) return 0.0;
    return (totalWins / gamesPlayed) * 100.0;
  }
}
