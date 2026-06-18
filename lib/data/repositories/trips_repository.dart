import '../models/trip.dart';

abstract class TripsRepository {
  // Create a new trip
  Future<Trip> createTrip(Trip trip);

  // Get all trips for a user
  Future<List<Trip>> getTripsByUserId(String userId);

  // Get a specific trip by ID
  Future<Trip?> getTripById(String tripId);

  // Update a trip
  Future<void> updateTrip(Trip trip);

  // Delete a trip
  Future<void> deleteTrip(String tripId);

  // Set a trip as current (and unset others)
  Future<void> setCurrentTrip(String tripId, String userId);

  // Get the current trip for a user
  Future<Trip?> getCurrentTrip(String userId);
}
