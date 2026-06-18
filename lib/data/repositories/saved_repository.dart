import '../models/place.dart';

abstract class SavedRepository {
  // Save a place for a user (with full Place object)
  Future<void> savePlace(String userId, Place place);

  // Unsave a place
  Future<void> unsavePlace(String userId, String placeId);

  // Get all saved places for a user (returns full Place objects)
  Future<List<Place>> getSavedPlaces(String userId);

  // Get saved place IDs (for quick checking)
  Future<List<String>> getSavedPlaceIds(String userId);

  // Check if a place is saved
  Future<bool> isPlaceSaved(String userId, String placeId);
}
