class PlayRequestModel {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String gameType;
  final String turfId;
  final DateTime date;
  final String slotTime;
  final String status;
  final DateTime createdAt;

  const PlayRequestModel({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.gameType,
    required this.turfId,
    required this.date,
    required this.slotTime,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'gameType': gameType,
      'turfId': turfId,
      'date': date.toIso8601String(),
      'slotTime': slotTime,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlayRequestModel.fromMap(Map<String, dynamic> map) {
    return PlayRequestModel(
      requestId: map['requestId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      gameType: map['gameType'] ?? '',
      turfId: map['turfId'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      slotTime: map['slotTime'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
