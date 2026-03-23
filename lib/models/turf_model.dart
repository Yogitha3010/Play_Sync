class TurfModel {
  final String turfId;
  final String ownerId;
  final String name;
  final String location;
  final double latitude;
  final double longitude;
  final List<String> gamesAvailable;
  final Map<String, int> courts; // {gameType: numberOfCourts}
  final double pricePerHour;
  final List<String> facilities; // ['AC', 'Changing Room', etc.]
  final String? contact;
  final String openingTime;
  final String closingTime;
  final DateTime createdAt;
  final bool isActive;

  TurfModel({
    required this.turfId,
    required this.ownerId,
    required this.name,
    required this.location,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.gamesAvailable = const [],
    this.courts = const {},
    this.pricePerHour = 0.0,
    this.facilities = const [],
    this.contact,
    this.openingTime = '06:00',
    this.closingTime = '22:00',
    required this.createdAt,
    this.isActive = true,
  });

  /// Returns a map of latitude and longitude for compatibility with older code.
  Map<String, double> get coordinates => {
    'latitude': latitude,
    'longitude': longitude,
  };

  /// Alias for backwards compatibility / expected model shape.
  List<String> get gameTypes => gamesAvailable;

  Map<String, dynamic> toMap() {
    return {
      'turfId': turfId,
      'ownerId': ownerId,
      'name': name,
      'turfName': name,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'coordinates': coordinates,
      'gamesAvailable': gamesAvailable,
      'gameTypes': gamesAvailable,
      'courts': courts,
      'pricePerHour': pricePerHour,
      'facilities': facilities,
      'contact': contact,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TurfModel.fromMap(Map<String, dynamic> map) {
    final coords = map['coordinates'];

    return TurfModel(
      turfId: map['turfId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? map['turfName'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? coords?['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? coords?['longitude'] ?? 0.0).toDouble(),
      gamesAvailable: List<String>.from(
        map['gamesAvailable'] ?? map['gameTypes'] ?? [],
      ),
      courts: Map<String, int>.from(map['courts'] ?? {}),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      facilities: List<String>.from(map['facilities'] ?? []),
      contact: map['contact'],
      openingTime: map['openingTime'] ?? '06:00',
      closingTime: map['closingTime'] ?? '22:00',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
