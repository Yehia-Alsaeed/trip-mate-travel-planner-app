import 'package:flutter/foundation.dart';
import '../data/models/country.dart';
import '../data/repositories/countries_repository.dart';
import '../data/repositories/restcountries/countries_repository_restcountries.dart';

class CountriesViewModel extends ChangeNotifier {
  final CountriesRepository _repository = CountriesRepositoryRestCountries();

  bool _isLoading = false;
  String? _errorMessage;
  List<Country> _allCountries = [];
  List<Country> _filteredCountries = [];
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Country> get allCountries => _allCountries;
  List<Country> get filteredCountries => _filteredCountries;
  String get searchQuery => _searchQuery;

  /// Load all countries
  Future<void> loadCountries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allCountries = await _repository.getAllCountries();
      _filteredCountries = _allCountries;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load countries: ${e.toString()}';
      _allCountries = [];
      _filteredCountries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set search query and filter countries locally
  void setSearchQuery(String query) {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredCountries = _allCountries;
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredCountries =
          _allCountries
              .where(
                (country) =>
                    country.nameCommon.toLowerCase().contains(lowerQuery) ||
                    country.nameOfficial.toLowerCase().contains(lowerQuery) ||
                    country.region.toLowerCase().contains(lowerQuery),
              )
              .toList();
    }

    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
