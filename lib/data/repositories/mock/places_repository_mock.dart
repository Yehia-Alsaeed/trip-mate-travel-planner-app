import '../../models/place.dart';
import '../places_repository.dart';

class PlacesRepositoryMock implements PlacesRepository {
  // Mock data for places
  static final List<Place> _mockPlaces = [
    // Cairo, Egypt places
    Place(
      id: 'place_giza_pyramids',
      name: 'Giza Pyramids',
      category: 'Ancient',
      rating: 4.9,
      city: 'Cairo',
      country: 'Egypt',
      description:
          'The iconic Pyramids of Giza, one of the Seven Wonders of the Ancient World',
      openingHours: '8:00 AM - 5:00 PM',
      location: PlaceLocation(latitude: 29.9792, longitude: 31.1342),
      photos: [],
    ),
    Place(
      id: 'place_1',
      name: 'Grand Egyptian Museum',
      category: 'Ancient',
      rating: 4.8,
      city: 'Cairo',
      country: 'Egypt',
      description: 'The largest archaeological museum in the world',
      openingHours: '9:00 AM - 6:00 PM',
      location: PlaceLocation(latitude: 30.0081, longitude: 31.2190),
      photos: [],
    ),
    Place(
      id: 'place_2',
      name: 'Salah Eldin Citadel',
      category: 'Ancient',
      rating: 4.6,
      city: 'Cairo',
      country: 'Egypt',
      description: 'Medieval Islamic fortification',
      openingHours: '8:00 AM - 5:00 PM',
      location: PlaceLocation(latitude: 30.0292, longitude: 31.2609),
      photos: [],
    ),
    Place(
      id: 'place_3',
      name: 'Khan el-Khalili',
      category: 'Shopping',
      rating: 4.4,
      city: 'Cairo',
      country: 'Egypt',
      description: 'Historic bazaar and souq',
      openingHours: '9:00 AM - 11:00 PM',
      location: PlaceLocation(latitude: 30.0475, longitude: 31.2622),
      photos: [],
    ),
    // Dubai places
    Place(
      id: 'place_4',
      name: 'Museum of the Future',
      category: 'Nature',
      rating: 4.9,
      city: 'Dubai',
      country: 'United Arab Emirates',
      description: 'Iconic museum showcasing future innovations',
      openingHours: '10:00 AM - 6:00 PM',
      location: PlaceLocation(latitude: 25.2188, longitude: 55.2793),
      photos: [],
    ),
    // Tokyo places
    Place(
      id: 'place_5',
      name: 'Shibuya Crossing',
      category: 'Shopping',
      rating: 4.7,
      city: 'Tokyo',
      country: 'Japan',
      description: 'World\'s busiest pedestrian crossing',
      openingHours: '24/7',
      location: PlaceLocation(latitude: 35.6598, longitude: 139.7006),
      photos: [],
    ),
    // Other cities
    Place(
      id: 'place_6',
      name: 'Great Wall of China',
      category: 'Ancient',
      rating: 4.9,
      city: 'Beijing',
      country: 'China',
      description: 'Ancient fortification system',
      openingHours: '7:30 AM - 6:00 PM',
      location: PlaceLocation(latitude: 40.4319, longitude: 116.5704),
      photos: [],
    ),
    Place(
      id: 'place_7',
      name: 'The Pearl Qatar',
      category: 'Shopping',
      rating: 4.5,
      city: 'Doha',
      country: 'Qatar',
      description: 'Artificial island with luxury shopping',
      openingHours: '10:00 AM - 10:00 PM',
      location: PlaceLocation(latitude: 25.3673, longitude: 51.5438),
      photos: [],
    ),
    Place(
      id: 'place_8',
      name: 'Kuwait Towers',
      category: 'Nature',
      rating: 4.6,
      city: 'Kuwait City',
      country: 'Kuwait',
      description: 'Iconic water towers and landmark',
      openingHours: '9:00 AM - 11:30 PM',
      location: PlaceLocation(latitude: 29.3897, longitude: 48.0037),
      photos: [],
    ),
    // Luxor, Egypt
    Place(
      id: 'place_9',
      name: 'Valley of the Kings',
      category: 'Ancient',
      rating: 4.8,
      city: 'Luxor',
      country: 'Egypt',
      description: 'Ancient Egyptian royal tombs',
      openingHours: '6:00 AM - 5:00 PM',
      location: PlaceLocation(latitude: 25.7400, longitude: 32.6022),
      photos: [],
    ),
    // Dahab, Egypt
    Place(
      id: 'place_10',
      name: 'Blue Hole',
      category: 'Nature',
      rating: 4.7,
      city: 'Dahab',
      country: 'Egypt',
      description: 'Famous diving spot',
      openingHours: '24/7',
      location: PlaceLocation(latitude: 28.5500, longitude: 34.5167),
      photos: [],
    ),
  ];

  @override
  Future<List<Place>> getPlacesByCity(String city) async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return _mockPlaces
        .where(
          (place) =>
              place.city != null &&
              place.city!.toLowerCase() == city.toLowerCase(),
        )
        .toList();
  }

  @override
  Future<List<Place>> getPlacesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPlaces
        .where(
          (place) => place.category.toLowerCase() == category.toLowerCase(),
        )
        .toList();
  }

  @override
  Future<List<Place>> getPlacesByInterests(List<String> interests) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPlaces
        .where(
          (place) => interests.any(
            (interest) =>
                place.category.toLowerCase() == interest.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final lowerQuery = query.toLowerCase();
    return _mockPlaces
        .where(
          (place) =>
              place.name.toLowerCase().contains(lowerQuery) ||
              (place.city != null &&
                  place.city!.toLowerCase().contains(lowerQuery)) ||
              (place.country != null &&
                  place.country!.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }

  @override
  Future<Place?> getPlaceById(String placeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockPlaces.firstWhere((place) => place.id == placeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Place>> getRecommendedPlaces({
    String? city,
    List<String>? interests,
    int? limit,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<Place> results = List.from(_mockPlaces);

    if (city != null) {
      results =
          results
              .where((place) => place.city?.toLowerCase() == city.toLowerCase())
              .toList();
    }

    if (interests != null && interests.isNotEmpty) {
      results =
          results
              .where(
                (place) => interests.any(
                  (interest) =>
                      place.category.toLowerCase() == interest.toLowerCase(),
                ),
              )
              .toList();
    }

    // Sort by rating (highest first)
    results.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));

    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<String>> getCitiesByCountry(String country) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cities =
        _mockPlaces
            .where(
              (place) =>
                  place.country != null &&
                  place.country!.toLowerCase() == country.toLowerCase() &&
                  place.city != null,
            )
            .map((place) => place.city!)
            .toSet()
            .toList();
    return cities;
  }

  @override
  Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
    required List<String> categories,
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    // Mock implementation - return places matching categories
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockPlaces
        .where(
          (place) => categories.any(
            (cat) => place.category.toLowerCase() == cat.toLowerCase(),
          ),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<List<Place>> searchPlacesByText({
    required String text,
    required List<String> categories,
    required double biasLat,
    required double biasLon,
    int limit = 20,
  }) async {
    // Mock implementation - delegate to searchPlaces
    return searchPlaces(text);
  }
}
