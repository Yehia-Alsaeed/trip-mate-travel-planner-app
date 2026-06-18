import 'package:flutter/foundation.dart';
import '../data/repositories/saved_repository.dart';
import '../data/repositories/firebase/saved_repository_firestore.dart';
import '../data/models/place.dart';

class SavedViewModel extends ChangeNotifier {
  final SavedRepository _savedRepository = SavedRepositoryFirestore();

  bool _isLoading = false;
  String? _errorMessage;
  List<Place> _savedPlaces = [];
  Set<String> _savedPlaceIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Place> get savedPlaces => _savedPlaces;
  Set<String> get savedPlaceIds => _savedPlaceIds;

  // Load saved places for a user
  Future<void> loadSavedPlaces(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load full Place objects directly from Firestore
      _savedPlaces = await _savedRepository.getSavedPlaces(userId);
      _savedPlaceIds = _savedPlaces.map((p) => p.id).toSet();

      debugPrint('SavedViewModel: Loaded ${_savedPlaces.length} saved places');
      _errorMessage = null;
    } catch (e) {
      debugPrint('SavedViewModel: Error loading saved places: $e');
      _errorMessage = 'Failed to load saved places: ${e.toString()}';
      _savedPlaces = [];
      _savedPlaceIds = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save a place (with Place object)
  Future<bool> savePlace(String userId, String placeId, {Place? place}) async {
    if (place == null) {
      _errorMessage = 'Place object is required to save';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save the full Place object to Firestore
      await _savedRepository.savePlace(userId, place);
      _savedPlaceIds.add(placeId);

      // Add to local list if not already present
      if (!_savedPlaces.any((p) => p.id == placeId)) {
        _savedPlaces.add(place);
      }

      debugPrint('SavedViewModel: Saved place ${place.name} (${place.id})');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('SavedViewModel: Error saving place: $e');
      _errorMessage = 'Failed to save place: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Unsave a place
  Future<bool> unsavePlace(String userId, String placeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _savedRepository.unsavePlace(userId, placeId);
      _savedPlaceIds.remove(placeId);
      _savedPlaces.removeWhere((p) => p.id == placeId);

      debugPrint('SavedViewModel: Unsaved place $placeId');
      _errorMessage = null;
      return true;
    } catch (e) {
      debugPrint('SavedViewModel: Error unsaving place: $e');
      _errorMessage = 'Failed to unsave place: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if a place is saved
  Future<bool> isPlaceSaved(String userId, String placeId) async {
    try {
      return await _savedRepository.isPlaceSaved(userId, placeId);
    } catch (e) {
      _errorMessage = 'Failed to check if place is saved: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
