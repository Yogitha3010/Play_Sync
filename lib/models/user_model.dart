class UserModel {
  final String userId;
  final String role; // 'player' or 'turfOwner'
  final String email;
  final String? name;
  final String? phone;
  final DateTime createdAt;
  final bool profileCompleted;

  UserModel({
    required this.userId,
    required this.role,
    required this.email,
    this.name,
    this.phone,
    required this.createdAt,
    this.profileCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'profileCompleted': profileCompleted,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      phone: map['phone'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      profileCompleted: map['profileCompleted'] ?? false,
    );
  }
}
