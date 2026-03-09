class TurfModel {
  final String turfId;
  final String ownerId;
  final String name;
  final String location;
  final Map<String, double> coordinates; // {latitude, longitude}
  final List<String> gamesAvailable;
  final Map<String, int> courts; // {gameType: numberOfCourts}
  final double pricePerHour;
  final List<String> facilities; // ['AC', 'Changing Room', etc.]
  final String? contact;
  final DateTime createdAt;
  final bool isActive;

  TurfModel({
    required this.turfId,
    required this.ownerId,
    required this.name,
    required this.location,
    this.coordinates = const {},
    this.gamesAvailable = const [],
    this.courts = const {},
    this.pricePerHour = 0.0,
    this.facilities = const [],
    this.contact,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'turfId': turfId,
      'ownerId': ownerId,
      'name': name,
      'location': location,
      'coordinates': coordinates,
      'gamesAvailable': gamesAvailable,
      'courts': courts,
      'pricePerHour': pricePerHour,
      'facilities': facilities,
      'contact': contact,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TurfModel.fromMap(Map<String, dynamic> map) {
    return TurfModel(
      turfId: map['turfId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      coordinates: Map<String, double>.from(map['coordinates'] ?? {}),
      gamesAvailable: List<String>.from(map['gamesAvailable'] ?? []),
      courts: Map<String, int>.from(map['courts'] ?? {}),
      pricePerHour: (map['pricePerHour'] ?? 0.0).toDouble(),
      facilities: List<String>.from(map['facilities'] ?? []),
      contact: map['contact'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}
