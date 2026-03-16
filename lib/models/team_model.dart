import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String teamId;
  final String teamName;
  final String createdBy;
  final List<String> players; // List of player IDs
  final String visibility; // 'public' or 'private'
  final List<String> joinRequests; // Pending player IDs for private teams
  final String gameType;
  final DateTime createdAt;

  TeamModel({
    required this.teamId,
    required this.teamName,
    required this.createdBy,
    this.players = const [],
    this.visibility = 'public',
    this.joinRequests = const [],
    required this.gameType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'createdBy': createdBy,
      'players': players,
      'visibility': visibility,
      'joinRequests': joinRequests,
      'gameType': gameType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map) {
    return TeamModel(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      players: List<String>.from(map['players'] ?? []),
      visibility: map['visibility'] ?? 'public',
      joinRequests: List<String>.from(map['joinRequests'] ?? []),
      gameType: map['gameType'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  factory TeamModel.fromDocument(DocumentSnapshot doc) {
    return TeamModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  TeamModel copyWith({
    String? teamId,
    String? teamName,
    String? createdBy,
    List<String>? players,
    String? visibility,
    List<String>? joinRequests,
    String? gameType,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdBy: createdBy ?? this.createdBy,
      players: players ?? this.players,
      visibility: visibility ?? this.visibility,
      joinRequests: joinRequests ?? this.joinRequests,
      gameType: gameType ?? this.gameType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
