import '../models/place.dart';

abstract class PlacesRepository {
  // Get places by city
  Future<List<Place>> getPlacesByCity(String city);

  // Get places by category
  Future<List<Place>> getPlacesByCategory(String category);

  // Get places by interests (multiple categories)
  Future<List<Place>> getPlacesByInterests(List<String> interests);

  // Search places by name
  Future<List<Place>> searchPlaces(String query);

  // Get a specific place by ID
  Future<Place?> getPlaceById(String placeId);

  // Get recommended places (based on user interests, city, etc.)
  Future<List<Place>> getRecommendedPlaces({
    String? city,
    List<String>? interests,
    int? limit,
  });

  // Get other cities in the same country
  Future<List<String>> getCitiesByCountry(String country);

  // Get nearby places (Geoapify)
  Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
    required List<String> categories,
    int radiusMeters = 3000,
    int limit = 20,
  });

  // Search places by text (Geoapify)
  Future<List<Place>> searchPlacesByText({
    required String text,
    required List<String> categories,
    required double biasLat,
    required double biasLon,
    int limit = 20,
  });
}
