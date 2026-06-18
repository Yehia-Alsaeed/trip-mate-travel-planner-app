import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/trip.dart';
import '../trips_repository.dart';

class TripsRepositoryFirestore implements TripsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trips';

  @override
  Future<Trip> createTrip(Trip trip) async {
    try {
      final docRef = await _firestore.collection(_collection).add(trip.toMap());
      return trip.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  @override
  Future<List<Trip>> getTripsByUserId(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => Trip.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tripId).get();
      if (!doc.exists) return null;
      return Trip.fromMap(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(trip.id)
          .update(trip.toMap());
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    try {
      await _firestore.collection(_collection).doc(tripId).delete();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  @override
  Future<void> setCurrentTrip(String tripId, String userId) async {
    try {
      // Unset all other trips as current
      final batch = _firestore.batch();
      final allTrips = await getTripsByUserId(userId);

      for (final trip in allTrips) {
        if (trip.id == tripId) {
          batch.update(_firestore.collection(_collection).doc(trip.id), {
            'isCurrent': true,
          });
        } else if (trip.isCurrent) {
          batch.update(_firestore.collection(_collection).doc(trip.id), {
            'isCurrent': false,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set current trip: $e');
    }
  }

  @override
  Future<Trip?> getCurrentTrip(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('userId', isEqualTo: userId)
              .where('isCurrent', isEqualTo: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) return null;
      return Trip.fromMap(
        querySnapshot.docs.first.id,
        querySnapshot.docs.first.data(),
      );
    } catch (e) {
      throw Exception('Failed to get current trip: $e');
    }
  }
}
