import 'package:flutter/foundation.dart';
import '../data/models/trip.dart';
import '../data/repositories/trips_repository.dart';
import '../data/repositories/firebase/trips_repository_firestore.dart';
import '../data/repositories/planner_repository.dart';
import '../data/repositories/firebase/planner_repository_firestore.dart';

class TripsViewModel extends ChangeNotifier {
  final TripsRepository _repository = TripsRepositoryFirestore();
  final PlannerRepository _plannerRepository = PlannerRepositoryFirestore();

  bool _isLoading = false;
  String? _errorMessage;
  List<Trip> _trips = [];
  Trip? _currentTrip;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Trip> get trips => _trips;
  Trip? get currentTrip => _currentTrip;

  // Load all trips for a user
  Future<void> loadTrips(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _trips = await _repository.getTripsByUserId(userId);
      _currentTrip = await _repository.getCurrentTrip(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load trips: ${e.toString()}';
      _trips = [];
      _currentTrip = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new trip
  Future<bool> createTrip({
    required String userId,
    required String city,
    required String country,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    required List<String> interests,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTrip = Trip(
        id: '', // Will be set by repository
        userId: userId,
        city: city,
        country: country,
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        interests: interests,
        createdAt: DateTime.now(),
        isCurrent: false,
      );

      final createdTrip = await _repository.createTrip(newTrip);

      // If this is the first trip, set it as current
      if (_trips.isEmpty) {
        await setCurrentTrip(createdTrip.id, userId);
      } else {
        _trips.add(createdTrip);
        notifyListeners();
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create trip: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a trip
  Future<bool> updateTrip(Trip trip) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateTrip(trip);

      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      }

      if (_currentTrip?.id == trip.id) {
        _currentTrip = trip;
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update trip: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a trip
  Future<bool> deleteTrip(String tripId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete all planner items for this trip first
      await _plannerRepository.deletePlannerItemsByTripId(tripId);

      // Then delete the trip
      await _repository.deleteTrip(tripId);
      _trips.removeWhere((t) => t.id == tripId);

      if (_currentTrip?.id == tripId) {
        _currentTrip = null;
        // Set another trip as current if available
        if (_trips.isNotEmpty) {
          await setCurrentTrip(_trips.first.id, userId);
        }
      }

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete trip: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set a trip as current
  Future<bool> setCurrentTrip(String tripId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setCurrentTrip(tripId, userId);

      // Update local state
      _trips =
          _trips.map((t) => t.copyWith(isCurrent: t.id == tripId)).toList();
      _currentTrip = _trips.firstWhere((t) => t.id == tripId);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set current trip: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
