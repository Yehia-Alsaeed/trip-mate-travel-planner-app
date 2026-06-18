class Trip {
  final String id;
  final String userId;
  final String city;
  final String country;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<String>
  interests; // Predefined: Ancient, Medical, Nature, Shopping, Food, etc.
  final DateTime createdAt;
  final bool isCurrent; // One trip marked as current

  Trip({
    required this.id,
    required this.userId,
    required this.city,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.interests,
    required this.createdAt,
    this.isCurrent = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'city': city,
      'country': country,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'interests': interests,
      'createdAt': createdAt.toIso8601String(),
      'isCurrent': isCurrent,
    };
  }

  // Create from Firestore document
  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,
      userId: map['userId'] as String,
      city: map['city'] as String,
      country: map['country'] as String? ?? '',
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      budget: (map['budget'] as num).toDouble(),
      interests: List<String>.from(map['interests'] as List),
      createdAt: DateTime.parse(map['createdAt'] as String),
      isCurrent: map['isCurrent'] as bool? ?? false,
    );
  }

  // Create a copy with updated fields
  Trip copyWith({
    String? id,
    String? userId,
    String? city,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    List<String>? interests,
    DateTime? createdAt,
    bool? isCurrent,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      city: city ?? this.city,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
