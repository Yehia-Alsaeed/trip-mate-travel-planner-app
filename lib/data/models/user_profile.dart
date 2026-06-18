class UserProfile {
  final String userId;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    this.updatedAt,
  });

  // Get first name from full name
  String get firstName {
    return name.trim().split(' ').first;
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
    );
  }

  // Create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
