import 'package:cloud_firestore/cloud_firestore.dart';

class PlayRequestModel {
  final String requestId;
  final String fromUserId;
  final String toUserId;
  final String gameType;
  final String turfId;
  final DateTime date;
  final String slotTime;
  final String status;
  final bool isReadByReceiver;
  final bool isReadBySender;
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
    this.isReadByReceiver = false,
    this.isReadBySender = false,
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
      'isReadByReceiver': isReadByReceiver,
      'isReadBySender': isReadBySender,
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
      date: _parseDateTime(map['date']),
      slotTime: map['slotTime'] ?? '',
      status: map['status'] ?? 'pending',
      isReadByReceiver: map['isReadByReceiver'] ?? false,
      isReadBySender: map['isReadBySender'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
