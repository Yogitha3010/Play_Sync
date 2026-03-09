class FeedbackModel {
  final String feedbackId;
  final String matchId;
  final String fromPlayerId;
  final String toPlayerId;
  final double rating; // 1.0 to 5.0
  final String? comments;
  final DateTime createdAt;

  FeedbackModel({
    required this.feedbackId,
    required this.matchId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.rating,
    this.comments,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'matchId': matchId,
      'fromPlayerId': fromPlayerId,
      'toPlayerId': toPlayerId,
      'rating': rating,
      'comments': comments,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      feedbackId: map['feedbackId'] ?? '',
      matchId: map['matchId'] ?? '',
      fromPlayerId: map['fromPlayerId'] ?? '',
      toPlayerId: map['toPlayerId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comments: map['comments'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
