class PlayerProfileModel {
  final String userId;
  final String? name;
  final String? username;
  final String? usernameLowercase;
  final double skillLevel; // 0.0 to 10.0
  final int gamesPlayed;
  final int totalWins;
  final int totalLosses;
  final double avgRating;
  final int totalRatings;
  final List<String> playedGames;
  final List<String> preferredSports;
  final Map<String, double> location; // {latitude, longitude}
  final String? locationAddress;
  final Map<String, dynamic> matchHistory;
  final DateTime? lastUpdated;

  PlayerProfileModel({
    required this.userId,
    this.name,
    this.username,
    this.usernameLowercase,
    this.skillLevel = 5.0,
    this.gamesPlayed = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.avgRating = 0.0,
    this.totalRatings = 0,
    this.playedGames = const [],
    this.preferredSports = const [],
    this.location = const {},
    this.locationAddress,
    this.matchHistory = const {},
    this.lastUpdated,
  });

  double get rating => avgRating;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'username': username,
      'usernameLowercase': usernameLowercase,
      'skillLevel': skillLevel,
      'gamesPlayed': gamesPlayed,
      'totalWins': totalWins,
      'totalLosses': totalLosses,
      'avgRating': avgRating,
      'rating': avgRating,
      'totalRatings': totalRatings,
      'playedGames': playedGames,
      'preferredSports': preferredSports,
      'preferredGames': preferredSports,
      'location': location,
      'locationAddress': locationAddress,
      'matchHistory': matchHistory,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PlayerProfileModel.fromMap(Map<String, dynamic> map) {
    return PlayerProfileModel(
      userId: map['userId'] ?? '',
      name: map['name'],
      username: map['username'],
      usernameLowercase: map['usernameLowercase'],
      skillLevel: (map['skillLevel'] ?? 5.0).toDouble(),
      gamesPlayed: map['gamesPlayed'] ?? 0,
      totalWins: map['totalWins'] ?? 0,
      totalLosses: map['totalLosses'] ?? 0,
      avgRating: (map['avgRating'] ?? map['rating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      playedGames: List<String>.from(map['playedGames'] ?? []),
      preferredSports: List<String>.from(
        map['preferredSports'] ?? map['preferredGames'] ?? [],
      ),
      location: Map<String, double>.from(map['location'] ?? {}),
      locationAddress: map['locationAddress'],
      matchHistory: Map<String, dynamic>.from(map['matchHistory'] ?? {}),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
    );
  }

  PlayerProfileModel copyWith({
    String? userId,
    String? name,
    String? username,
    String? usernameLowercase,
    double? skillLevel,
    int? gamesPlayed,
    int? totalWins,
    int? totalLosses,
    double? avgRating,
    int? totalRatings,
    List<String>? playedGames,
    List<String>? preferredSports,
    Map<String, double>? location,
    String? locationAddress,
    Map<String, dynamic>? matchHistory,
    DateTime? lastUpdated,
  }) {
    return PlayerProfileModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      usernameLowercase: usernameLowercase ?? this.usernameLowercase,
      skillLevel: skillLevel ?? this.skillLevel,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
      playedGames: playedGames ?? this.playedGames,
      preferredSports: preferredSports ?? this.preferredSports,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      matchHistory: matchHistory ?? this.matchHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  double get winPercentage {
    if (gamesPlayed == 0) return 0.0;
    return (totalWins / gamesPlayed) * 100.0;
  }
}
