class FeedbackModel {
  final String feedbackId;
  final String matchId;
  final String fromUserId;
  final String toUserId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String gameType;
  final DateTime createdAt;

  FeedbackModel({
    required this.feedbackId,
    required this.matchId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.comment,
    required this.gameType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'matchId': matchId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'rating': rating,
      'comment': comment,
      'gameType': gameType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      feedbackId: map['feedbackId'] ?? '',
      matchId: map['matchId'] ?? '',
      fromUserId: map['fromUserId'] ?? map['fromPlayerId'] ?? '',
      toUserId: map['toUserId'] ?? map['toPlayerId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? map['comments'],
      gameType: map['gameType'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
