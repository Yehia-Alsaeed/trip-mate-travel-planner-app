import 'dart:math' as math;

class Place {
  final String id;
  final String name;
  final String category; // Ancient, Medical, Nature, Shopping, Food, etc.
  final double? rating; // 0.0 to 5.0
  final List<String> photos; // URLs or asset paths
  final String? openingHours; // e.g., "9:00 AM - 6:00 PM"
  final PlaceLocation? location; // Latitude, longitude
  final String? description;
  final String? city;
  final String? country;
  final String? address; // Full address from API
  final String? phone; // Phone number
  final String? website; // Website URL
  final double? distance; // Distance in km (calculated)

  Place({
    required this.id,
    required this.name,
    required this.category,
    this.rating,
    this.photos = const [],
    this.openingHours,
    this.location,
    this.description,
    this.city,
    this.country,
    this.address,
    this.phone,
    this.website,
    this.distance,
  });

  // Convert to Map (for mock data or future API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'photos': photos,
      'openingHours': openingHours,
      'location': location?.toMap(),
      'description': description,
      'city': city,
      'country': country,
      'address': address,
      'phone': phone,
      'website': website,
      'distance': distance,
    };
  }

  // Create from Map (null-safe)
  factory Place.fromMap(Map<String, dynamic> map) {
    // Handle photos - could be List or null
    List<String> photosList = [];
    if (map['photos'] != null) {
      if (map['photos'] is List) {
        photosList = List<String>.from(
          (map['photos'] as List).map((e) => e.toString()),
        );
      }
    }

    // Handle location - could be Map or null
    PlaceLocation? locationObj;
    if (map['location'] != null && map['location'] is Map) {
      try {
        locationObj = PlaceLocation.fromMap(
          map['location'] as Map<String, dynamic>,
        );
      } catch (e) {
        // If location parsing fails, leave it null
        locationObj = null;
      }
    }

    return Place(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      category: map['category'] as String? ?? 'Other',
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      photos: photosList,
      openingHours: map['openingHours'] as String?,
      location: locationObj,
      description: map['description'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      distance:
          map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    );
  }

  // Create a copy with updated fields
  Place copyWith({
    String? id,
    String? name,
    String? category,
    double? rating,
    List<String>? photos,
    String? openingHours,
    PlaceLocation? location,
    String? description,
    String? city,
    String? country,
    String? address,
    String? phone,
    String? website,
    double? distance,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      photos: photos ?? this.photos,
      openingHours: openingHours ?? this.openingHours,
      location: location ?? this.location,
      description: description ?? this.description,
      city: city ?? this.city,
      country: country ?? this.country,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      distance: distance ?? this.distance,
    );
  }
}

class PlaceLocation {
  final double latitude;
  final double longitude;

  PlaceLocation({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory PlaceLocation.fromMap(Map<String, dynamic> map) {
    return PlaceLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  // Calculate distance to another location (Haversine formula)
  double distanceTo(PlaceLocation other) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);

    final double a =
        (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(latitude).cos() *
            _toRadians(other.latitude).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    final double c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}

// Extension for math functions
extension MathExtensions on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double asin() => math.asin(this);
}
