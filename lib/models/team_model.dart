import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String teamId;
  final String teamName;
  final String createdBy;
  final List<String> players; // List of player IDs
  final String gameType;
  final DateTime createdAt;

  TeamModel({
    required this.teamId,
    required this.teamName,
    required this.createdBy,
    this.players = const [],
    required this.gameType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'createdBy': createdBy,
      'players': players,
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
    String? gameType,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      createdBy: createdBy ?? this.createdBy,
      players: players ?? this.players,
      gameType: gameType ?? this.gameType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
