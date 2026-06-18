import 'package:flutter/foundation.dart';
import '../data/models/place.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/geoapify/places_repository_geoapify.dart';
import '../data/repositories/mock/places_repository_mock.dart';
import '../data/services/location_service.dart';
import '../data/constants/geoapify_category_map.dart';

class DiscoverViewModel extends ChangeNotifier {
  // Use Geoapify for discover places screen (nearby places, search)
  final PlacesRepository _geoapifyRepository = PlacesRepositoryGeoapify();
  // Use Mock for recommended places (home screen)
  final PlacesRepository _mockRepository = PlacesRepositoryMock();
  final LocationService _locationService = LocationService();

  // Initialize with default category and load places
  Future<void> init() async {
    _selectedCategory = 'Ancient'; // Default category
    await loadNearbyPlaces();
  }

  // Set category and reload places
  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    notifyListeners();
    await loadNearbyPlaces();
  }

  double? _currentLat;
  double? _currentLon;

  bool _isLoading = false;
  String? _errorMessage;
  List<Place> _places = [];
  List<Place> _recommendedPlaces = [];
  String? _selectedCity;
  List<String> _selectedInterests = [];
  String _searchQuery = '';
  String _selectedCategory = 'Ancient'; // Default category

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Place> get places => _places;
  List<Place> get recommendedPlaces => _recommendedPlaces;
  String? get selectedCity => _selectedCity;
  List<String> get selectedInterests => _selectedInterests;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Set selected city
  void setSelectedCity(String? city) {
    _selectedCity = city;
    notifyListeners();
  }

  // Set selected interests
  void setSelectedInterests(List<String> interests) {
    _selectedInterests = interests;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Load nearby places (near me) - uses selected category
  Future<void> loadNearbyPlaces({
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    debugPrint(
      'DiscoverViewModel: loadNearbyPlaces called with category: $_selectedCategory',
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location
      final location = await _locationService.getCurrentLocation();

      if (location == null) {
        debugPrint('❌ Location is null - cannot proceed');
        _errorMessage =
            'Unable to get your location. Please enable location services in device settings.';
        _places = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentLat = location['latitude'];
      _currentLon = location['longitude'];

      debugPrint('Location: lat=$_currentLat, lon=$_currentLon');
      debugPrint('Category: $_selectedCategory');

      // Get Geoapify categories for the selected app category
      final geoapifyCategories = GeoapifyCategoryMap.geoapifyCategoriesFor(
        _selectedCategory,
      );
      debugPrint('Geoapify categories: $geoapifyCategories');

      _places = await _geoapifyRepository.getNearbyPlaces(
        lat: _currentLat!,
        lon: _currentLon!,
        categories: geoapifyCategories,
        radiusMeters: radiusMeters,
        limit: limit,
      );
      _errorMessage = null;
      debugPrint(
        'DiscoverViewModel: Successfully loaded ${_places.length} nearby places',
      );
    } catch (e, stackTrace) {
      debugPrint('DiscoverViewModel: Error loading nearby places: $e');
      debugPrint('DiscoverViewModel: Stack trace: $stackTrace');
      _errorMessage = 'Failed to load nearby places: ${e.toString()}';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load recommended places (uses Mock repository for home screen)
  Future<void> loadRecommendedPlaces({
    String? city,
    List<String>? interests,
    int limit = 10,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Always use mock repository for recommended places (home screen)
      _recommendedPlaces = await _mockRepository.getRecommendedPlaces(
        city: city,
        interests: interests,
        limit: limit,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load recommended places: ${e.toString()}';
      _recommendedPlaces = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search places - uses selected category
  Future<void> searchPlaces(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        // Reload nearby places when search is cleared
        await loadNearbyPlaces();
        return;
      }

      // Get current location for bias
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLat = location['latitude'];
        _currentLon = location['longitude'];

        // Get Geoapify categories for the selected app category
        final geoapifyCategories = GeoapifyCategoryMap.geoapifyCategoriesFor(
          _selectedCategory,
        );

        _places = await _geoapifyRepository.searchPlacesByText(
          text: query,
          categories: geoapifyCategories,
          biasLat: _currentLat!,
          biasLon: _currentLon!,
        );
      } else {
        // Fallback to mock if location unavailable
        _places = await _mockRepository.searchPlaces(query);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to search places: ${e.toString()}';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get places by city (search by text)
  Future<void> loadPlacesByCity(String city) async {
    _selectedCity = city;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location for bias
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLat = location['latitude'];
        _currentLon = location['longitude'];
        _places = await _geoapifyRepository.searchPlacesByText(
          text: city,
          categories: ['Food', 'Shopping', 'Nature', 'Ancient', 'Medical'],
          biasLat: _currentLat!,
          biasLon: _currentLon!,
        );
      } else {
        // Fallback to mock if location unavailable
        _places = await _mockRepository.getPlacesByCity(city);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load places: ${e.toString()}';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get places by category (uses Geoapify for discover screen)
  Future<void> loadPlacesByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location for Geoapify
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLat = location['latitude'];
        _currentLon = location['longitude'];
        _places = await _geoapifyRepository.getNearbyPlaces(
          lat: _currentLat!,
          lon: _currentLon!,
          categories: [category],
        );
      } else {
        // Fallback to mock if location unavailable
        _places = await _mockRepository.getPlacesByCategory(category);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load places: ${e.toString()}';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get places by interests (uses Geoapify for discover screen)
  Future<void> loadPlacesByInterests(List<String> interests) async {
    _selectedInterests = interests;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current location for Geoapify
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _currentLat = location['latitude'];
        _currentLon = location['longitude'];
        _places = await _geoapifyRepository.getNearbyPlaces(
          lat: _currentLat!,
          lon: _currentLon!,
          categories: interests,
        );
      } else {
        // Fallback to mock if location unavailable
        _places = await _mockRepository.getPlacesByInterests(interests);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load places: ${e.toString()}';
      _places = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific place by ID (tries Geoapify first, then mock)
  Future<Place?> getPlaceById(String placeId) async {
    try {
      // Try Geoapify first (for places from API)
      final place = await _geoapifyRepository.getPlaceById(placeId);
      if (place != null) return place;

      // Fallback to mock
      return await _mockRepository.getPlaceById(placeId);
    } catch (e) {
      _errorMessage = 'Failed to get place: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Get other cities in the same country (uses mock)
  Future<List<String>> getCitiesByCountry(String country) async {
    try {
      return await _mockRepository.getCitiesByCountry(country);
    } catch (e) {
      _errorMessage = 'Failed to get cities: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  // Clear search and filters - reloads with current category
  void clearFilters() {
    _searchQuery = '';
    _selectedCity = null;
    _selectedInterests = [];
    notifyListeners();
    // Reload nearby places with current category when filters are cleared
    loadNearbyPlaces();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
