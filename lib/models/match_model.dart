class MatchModel {
  final String matchId;
  final String gameType;
  final String location;
  final Map<String, double> coordinates;
  final String? turfId;
  final String createdBy;
  final List<String> players; // All player IDs
  final List<String> teamA;
  final List<String> teamB;
  final Map<String, String> playerPositions; // {playerId: position}
  final String matchStatus; // 'pending', 'active', 'completed', 'cancelled'
  final Map<String, dynamic>? tossResult; // {winner: 'teamA'/'teamB', choice: 'bat'/'bowl'}
  final Map<String, int>? score; // {teamA: score, teamB: score}
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final int maxPlayers;
  final String? matchGroupId;

  MatchModel({
    required this.matchId,
    required this.gameType,
    required this.location,
    this.coordinates = const {},
    this.turfId,
    required this.createdBy,
    this.players = const [],
    this.teamA = const [],
    this.teamB = const [],
    this.playerPositions = const {},
    this.matchStatus = 'pending',
    this.tossResult,
    this.score,
    required this.createdAt,
    this.scheduledTime,
    this.maxPlayers = 10,
    this.matchGroupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'gameType': gameType,
      'location': location,
      'coordinates': coordinates,
      'turfId': turfId,
      'createdBy': createdBy,
      'players': players,
      'teamA': teamA,
      'teamB': teamB,
      'playerPositions': playerPositions,
      'matchStatus': matchStatus,
      'tossResult': tossResult,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'maxPlayers': maxPlayers,
      'matchGroupId': matchGroupId,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      gameType: map['gameType'] ?? '',
      location: map['location'] ?? '',
      coordinates: Map<String, double>.from(map['coordinates'] ?? {}),
      turfId: map['turfId'],
      createdBy: map['createdBy'] ?? '',
      players: List<String>.from(map['players'] ?? []),
      teamA: List<String>.from(map['teamA'] ?? []),
      teamB: List<String>.from(map['teamB'] ?? []),
      playerPositions: Map<String, String>.from(map['playerPositions'] ?? {}),
      matchStatus: map['matchStatus'] ?? 'pending',
      tossResult: map['tossResult'] != null
          ? Map<String, String>.from(map['tossResult'])
          : null,
      score: map['score'] != null
          ? Map<String, int>.from(map['score'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'])
          : null,
      maxPlayers: map['maxPlayers'] ?? 10,
      matchGroupId: map['matchGroupId'],
    );
  }

  MatchModel copyWith({
    String? matchId,
    String? gameType,
    String? location,
    Map<String, double>? coordinates,
    String? turfId,
    String? createdBy,
    List<String>? players,
    List<String>? teamA,
    List<String>? teamB,
    Map<String, String>? playerPositions,
    String? matchStatus,
    Map<String, dynamic>? tossResult,
    Map<String, int>? score,
    DateTime? createdAt,
    DateTime? scheduledTime,
    int? maxPlayers,
    String? matchGroupId,
  }) {
    return MatchModel(
      matchId: matchId ?? this.matchId,
      gameType: gameType ?? this.gameType,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      turfId: turfId ?? this.turfId,
      createdBy: createdBy ?? this.createdBy,
      players: players ?? this.players,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      playerPositions: playerPositions ?? this.playerPositions,
      matchStatus: matchStatus ?? this.matchStatus,
      tossResult: tossResult ?? this.tossResult,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      matchGroupId: matchGroupId ?? this.matchGroupId,
    );
  }
}
