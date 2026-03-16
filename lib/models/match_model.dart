class MatchModel {
  final String matchId;
  final String createdBy;
  final String gameType;
  final String turfId;
  final String matchStatus; // 'pending', 'active', 'completed', 'cancelled'
  final String location;
  final List<String> players; // All player IDs
  final DateTime createdAt;

  // Additional backwards compatible UI fields if needed
  final List<String> teamA;
  final List<String> teamB;
  final Map<String, int>? score;
  final Map<String, dynamic>? tossResult;
  final DateTime? scheduledTime;
  final int maxPlayers;
  final String visibility; // 'public' or 'team'
  final String? teamId;

  MatchModel({
    required this.matchId,
    required this.createdBy,
    required this.gameType,
    required this.turfId,
    this.matchStatus = 'pending',
    this.location = '',
    this.players = const [],
    required this.createdAt,
    this.teamA = const [],
    this.teamB = const [],
    this.score,
    this.tossResult,
    this.scheduledTime,
    this.maxPlayers = 10,
    this.visibility = 'public',
    this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'createdBy': createdBy,
      'gameType': gameType,
      'turfId': turfId,
      'matchStatus': matchStatus,
      'status': matchStatus,
      'location': location,
      'players': players,
      'createdAt': createdAt.toIso8601String(),
      'teamA': teamA,
      'teamB': teamB,
      'score': score,
      'tossResult': tossResult,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'maxPlayers': maxPlayers,
      'visibility': visibility,
      'teamId': teamId,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      gameType: map['gameType'] ?? '',
      turfId: map['turfId'] ?? '',
      matchStatus: map['matchStatus'] ?? map['status'] ?? 'pending',
      location: map['location'] ?? '',
      players: List<String>.from(map['players'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      teamA: List<String>.from(map['teamA'] ?? []),
      teamB: List<String>.from(map['teamB'] ?? []),
      tossResult: map['tossResult'] != null
          ? Map<String, dynamic>.from(map['tossResult'])
          : null,
      score: map['score'] != null ? Map<String, int>.from(map['score']) : null,
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'])
          : null,
      maxPlayers: map['maxPlayers'] ?? 10,
      visibility: map['visibility'] ?? 'public',
      teamId: map['teamId'],
    );
  }

  MatchModel copyWith({
    String? matchId,
    String? createdBy,
    String? gameType,
    String? turfId,
    String? matchStatus,
    String? location,
    List<String>? players,
    DateTime? createdAt,
    List<String>? teamA,
    List<String>? teamB,
    Map<String, int>? score,
    Map<String, dynamic>? tossResult,
    DateTime? scheduledTime,
    int? maxPlayers,
    String? visibility,
    String? teamId,
  }) {
    return MatchModel(
      matchId: matchId ?? this.matchId,
      createdBy: createdBy ?? this.createdBy,
      gameType: gameType ?? this.gameType,
      turfId: turfId ?? this.turfId,
      matchStatus: matchStatus ?? this.matchStatus,
      location: location ?? this.location,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      score: score ?? this.score,
      tossResult: tossResult ?? this.tossResult,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      visibility: visibility ?? this.visibility,
      teamId: teamId ?? this.teamId,
    );
  }
}
