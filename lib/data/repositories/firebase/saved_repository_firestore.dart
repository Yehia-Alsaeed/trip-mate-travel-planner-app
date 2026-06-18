import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/place.dart';
import '../saved_repository.dart';

class SavedRepositoryFirestore implements SavedRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'savedPlaces';

  @override
  Future<void> savePlace(String userId, Place place) async {
    try {
      await _firestore.collection(_collection).doc('${userId}_${place.id}').set(
        {
          'userId': userId,
          'placeId': place.id,
          'place': place.toMap(), // Store full Place object
          'savedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to save place: $e');
    }
  }

  @override
  Future<void> unsavePlace(String userId, String placeId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc('${userId}_$placeId')
          .delete();
    } catch (e) {
      throw Exception('Failed to unsave place: $e');
    }
  }

  @override
  Future<List<Place>> getSavedPlaces(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      final places = <Place>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Try to get Place from stored data
        if (data.containsKey('place') && data['place'] is Map) {
          try {
            final placeMap = data['place'] as Map<String, dynamic>;
            final place = Place.fromMap(placeMap);
            places.add(place);
          } catch (e) {
            // If parsing fails, skip this place
            continue;
          }
        }
      }

      return places;
    } catch (e) {
      throw Exception('Failed to get saved places: $e');
    }
  }

  @override
  Future<List<String>> getSavedPlaceIds(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['placeId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get saved place IDs: $e');
    }
  }

  @override
  Future<bool> isPlaceSaved(String userId, String placeId) async {
    try {
      final doc =
          await _firestore
              .collection(_collection)
              .doc('${userId}_$placeId')
              .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check if place is saved: $e');
    }
  }
}
