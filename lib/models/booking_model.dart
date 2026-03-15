class BookingModel {
  final String bookingId;
  final String turfId;
  final String turfOwnerId;
  final String playerId;
  final String? matchId; // Optional, if booked via match creation
  final String gameType;
  final DateTime bookingDate; // The day of the booking
  final String slotTime; // e.g., "18:00 - 19:00"
  final DateTime createdAt;
  final String status; // 'confirmed', 'cancelled', 'completed'

  BookingModel({
    required this.bookingId,
    required this.turfId,
    required this.turfOwnerId,
    required this.playerId,
    this.matchId,
    required this.gameType,
    required this.bookingDate,
    required this.slotTime,
    required this.createdAt,
    this.status = 'confirmed',
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'turfId': turfId,
      'turfOwnerId': turfOwnerId,
      'playerId': playerId,
      'matchId': matchId,
      'gameType': gameType,
      'bookingDate': bookingDate.toIso8601String(),
      'slotTime': slotTime,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      bookingId: map['bookingId'] ?? '',
      turfId: map['turfId'] ?? '',
      turfOwnerId: map['turfOwnerId'] ?? '',
      playerId: map['playerId'] ?? '',
      matchId: map['matchId'],
      gameType: map['gameType'] ?? '',
      bookingDate: map['bookingDate'] != null
          ? DateTime.parse(map['bookingDate'])
          : DateTime.now(),
      slotTime: map['slotTime'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      status: map['status'] ?? 'confirmed',
    );
  }
}
