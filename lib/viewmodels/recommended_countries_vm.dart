import 'package:flutter/foundation.dart';
import '../data/models/country.dart';
import '../data/repositories/countries_repository.dart';
import '../data/repositories/restcountries/countries_repository_restcountries.dart';
import '../data/services/location_service.dart';
import '../data/services/reverse_geocoding_service.dart';

class RecommendedCountriesViewModel extends ChangeNotifier {
  final CountriesRepository _repository = CountriesRepositoryRestCountries();
  final LocationService _locationService = LocationService();
  final ReverseGeocodingService _reverseGeocodingService =
      ReverseGeocodingService();

  bool _isLoading = false;
  String? _errorMessage;
  Country? _userCountry;
  List<Country> _recommended = [];
  bool _hasLoaded = false; // Simple cache flag

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Country? get userCountry => _userCountry;
  List<Country> get recommended => _recommended;

  /// Quality filter: filters out territories and low-quality countries
  /// Note: independent and unMember are not in API response (removed to include languages/currencies)
  /// So we filter based on capital and population only
  bool _isQualityCountry(Country country) {
    return country.capital.isNotEmpty && country.population >= 500000;
  }

  /// Load recommended countries based on user's location
  Future<void> loadRecommendedCountries() async {
    // Simple caching: if already loaded, don't reload
    if (_hasLoaded && _recommended.isNotEmpty) {
      debugPrint('RecommendedCountriesViewModel: Already loaded, skipping');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('RecommendedCountriesViewModel: Starting load...');

      // Step 1: Get user current location
      debugPrint('Step 1: Getting user location...');
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _errorMessage =
            'Unable to get your location. Please enable location services.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final lat = location['latitude'] as double;
      final lon = location['longitude'] as double;
      debugPrint('User location: lat=$lat, lon=$lon');

      // Step 2: Get country code via reverse geocoding
      debugPrint('Step 2: Getting country code via reverse geocoding...');
      final countryCode = await _reverseGeocodingService.getCountryCode(
        lat: lat,
        lon: lon,
      );

      if (countryCode == null) {
        _errorMessage =
            'Unable to determine your country. Using default recommendations.';
        // Fallback to default recommendations
        await _loadDefaultRecommendations();
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Country code: $countryCode');

      // Step 3: Fetch user country
      debugPrint('Step 3: Fetching user country...');
      _userCountry = await _repository.getCountryByCode(countryCode);
      debugPrint('User country: ${_userCountry!.nameCommon}');

      // Step 4: Build recommendations
      debugPrint('Step 4: Building recommendations...');
      await _buildRecommendations(_userCountry!);

      _errorMessage = null;
      _hasLoaded = true;
      debugPrint(
        'RecommendedCountriesViewModel: Successfully loaded ${_recommended.length} recommendations',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'RecommendedCountriesViewModel: Error loading recommendations: $e',
      );
      debugPrint('Stack trace: $stackTrace');
      _errorMessage = 'Failed to load recommendations: ${e.toString()}';

      // Fallback to default recommendations
      await _loadDefaultRecommendations();
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Build recommendations: Priority A (same region) → Priority B (same subregion) → Priority C (fallback)
  /// Always returns exactly 6 countries with quality filtering
  Future<void> _buildRecommendations(Country userCountry) async {
    _recommended = [];

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('BUILDING RECOMMENDATIONS');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('User Country: ${userCountry.nameCommon} (${userCountry.cca2})');
    debugPrint('User Region: ${userCountry.region}');
    debugPrint('User Subregion: ${userCountry.subregion}');
    debugPrint('═══════════════════════════════════════════════════════');

    // Track counts for stats
    int subregionPickedCount = 0;
    int regionPickedCount = 0;
    int fallbackPickedCount = 0;

    try {
      // Priority A: Get countries from same region
      debugPrint(
        'Priority A: Fetching countries from region: ${userCountry.region}',
      );
      final regionCountries = await _repository.getCountriesByRegion(
        userCountry.region,
      );
      debugPrint('Loaded ${regionCountries.length} countries from region');

      // Apply quality filter and exclude user's own country
      final userCca2 = userCountry.cca2;
      final regionFiltered =
          regionCountries
              .where(
                (country) =>
                    country.cca2 != null &&
                    country.cca2 != userCca2 &&
                    _isQualityCountry(country),
              )
              .toList();
      debugPrint(
        'After quality filter and excluding user country: ${regionFiltered.length} countries',
      );

      // Priority B: If subregion exists, prioritize same subregion
      List<Country> subregionMatches = [];
      List<Country> otherRegionCountries = [];

      if (userCountry.subregion.isNotEmpty &&
          userCountry.subregion != 'Unknown') {
        debugPrint(
          'Priority B: Filtering by subregion: ${userCountry.subregion}',
        );
        subregionMatches =
            regionFiltered
                .where(
                  (country) =>
                      country.subregion == userCountry.subregion &&
                      country.cca2 != null &&
                      country.cca2 != userCca2,
                )
                .toList();
        otherRegionCountries =
            regionFiltered
                .where((country) => country.subregion != userCountry.subregion)
                .toList();
        debugPrint(
          'Found ${subregionMatches.length} quality countries in same subregion',
        );
        debugPrint(
          'Found ${otherRegionCountries.length} quality other countries in region',
        );
      } else {
        debugPrint(
          'Priority B: No subregion available, using all region countries',
        );
        otherRegionCountries = regionFiltered;
      }

      // Build recommendation list: subregion first, then other region countries
      _recommended = [...subregionMatches, ...otherRegionCountries];

      // Remove duplicates (by cca2)
      final seen = <String>{};
      _recommended =
          _recommended.where((country) {
            final code = country.cca2;
            if (code == null || seen.contains(code)) {
              return false;
            }
            seen.add(code);
            return true;
          }).toList();

      // Track how many we picked from each source (before trimming)
      subregionPickedCount = subregionMatches.length;
      regionPickedCount = otherRegionCountries.length;

      debugPrint(
        'After Priority A+B: ${_recommended.length} quality countries selected',
      );
      debugPrint('  - From subregion: $subregionPickedCount');
      debugPrint('  - From region (other): $regionPickedCount');

      // Priority C: Fill remaining slots from fallback list
      if (_recommended.length < 6) {
        final needed = 6 - _recommended.length;
        debugPrint(
          'Priority C: Need $needed more countries, using fallback list',
        );

        final fallbackCodes = [
          'FR',
          'IT',
          'ES',
          'TR',
          'AE',
          'SA',
          'GB',
          'DE',
          'US',
          'JP',
        ];

        // Get existing cca2 codes to avoid duplicates
        final existingCodes =
            _recommended
                .map((c) => c.cca2)
                .where((code) => code != null)
                .cast<String>()
                .toSet();
        if (userCca2 != null) {
          existingCodes.add(userCca2); // Also exclude user country
        }

        // Filter fallback codes
        final fallbackCodesToFetch =
            fallbackCodes
                .where((code) => !existingCodes.contains(code))
                .take(needed)
                .toList();

        debugPrint(
          'Fetching ${fallbackCodesToFetch.length} fallback countries: $fallbackCodesToFetch',
        );

        if (fallbackCodesToFetch.isNotEmpty) {
          try {
            final fallbackCountries = await _repository.getCountriesByCodes(
              fallbackCodesToFetch,
            );
            // Apply quality filter to fallback countries
            final qualityFallback =
                fallbackCountries
                    .where((country) => _isQualityCountry(country))
                    .toList();
            _recommended.addAll(qualityFallback);
            fallbackPickedCount = qualityFallback.length;
            debugPrint(
              'Added $fallbackPickedCount quality countries from fallback',
            );
          } catch (e) {
            debugPrint('Error loading fallback countries: $e');
          }
        }
      }

      // Ensure exactly 6 results (take first 6 if more)
      if (_recommended.length > 6) {
        debugPrint(
          'Trimming to exactly 6 countries (had ${_recommended.length})',
        );
        // Adjust counts based on what we're keeping
        final beforeTrim = _recommended.length;
        _recommended = _recommended.take(6).toList();
        final trimmed = beforeTrim - 6;

        // Adjust counts proportionally
        if (trimmed > 0 && subregionPickedCount + regionPickedCount > 0) {
          final totalRegion = subregionPickedCount + regionPickedCount;
          final regionRatio = totalRegion / beforeTrim;
          final trimmedFromRegion = (trimmed * regionRatio).round();
          final trimmedFromSubregion =
              (trimmedFromRegion * (subregionPickedCount / totalRegion))
                  .round();
          subregionPickedCount = (subregionPickedCount - trimmedFromSubregion)
              .clamp(0, 6);
          regionPickedCount = (regionPickedCount -
                  (trimmedFromRegion - trimmedFromSubregion))
              .clamp(0, 6);
        }
      } else if (_recommended.length < 6) {
        debugPrint(
          'WARNING: Only ${_recommended.length} countries available (target: 6)',
        );
        // If we still don't have 6, try to get more from fallback
        final needed = 6 - _recommended.length;
        final allFallbackCodes = [
          'FR',
          'IT',
          'ES',
          'TR',
          'AE',
          'SA',
          'GB',
          'DE',
          'US',
          'JP',
          'CA',
          'AU',
          'NZ',
          'BR',
          'MX',
        ];
        final existingCodes =
            _recommended
                .map((c) => c.cca2)
                .where((code) => code != null)
                .cast<String>()
                .toSet();
        if (userCountry.cca2 != null) {
          existingCodes.add(userCountry.cca2!);
        }

        final additionalCodes =
            allFallbackCodes
                .where((code) => !existingCodes.contains(code))
                .take(needed)
                .toList();

        if (additionalCodes.isNotEmpty) {
          try {
            final additional = await _repository.getCountriesByCodes(
              additionalCodes,
            );
            final qualityAdditional =
                additional
                    .where((country) => _isQualityCountry(country))
                    .toList();
            _recommended.addAll(qualityAdditional);
            fallbackPickedCount += qualityAdditional.length;
            _recommended = _recommended.take(6).toList();
            debugPrint(
              'Added ${qualityAdditional.length} more quality countries to reach 6',
            );
          } catch (e) {
            debugPrint('Error loading additional fallback: $e');
          }
        }
      }

      // Final stats: ensure counts match actual final list
      final finalCount = _recommended.length;
      // Recalculate counts from final list
      subregionPickedCount = 0;
      regionPickedCount = 0;
      fallbackPickedCount = 0;

      final finalSubregionCodes = subregionMatches.map((c) => c.cca2).toSet();
      final finalRegionCodes = otherRegionCountries.map((c) => c.cca2).toSet();

      for (final country in _recommended) {
        if (finalSubregionCodes.contains(country.cca2)) {
          subregionPickedCount++;
        } else if (finalRegionCodes.contains(country.cca2)) {
          regionPickedCount++;
        } else {
          fallbackPickedCount++;
        }
      }

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('FINAL RECOMMENDATIONS: $finalCount countries');
      debugPrint('  - subregionPickedCount: $subregionPickedCount');
      debugPrint('  - regionPickedCount: $regionPickedCount');
      debugPrint('  - fallbackPickedCount: $fallbackPickedCount');
      debugPrint('  - finalCount: $finalCount');
      debugPrint(
        'Countries: ${_recommended.map((c) => '${c.nameCommon} (${c.cca2})').join(', ')}',
      );
      debugPrint('═══════════════════════════════════════════════════════');

      // Final check: ensure we have exactly 6
      if (_recommended.length != 6) {
        debugPrint(
          'ERROR: Expected 6 countries but got ${_recommended.length}',
        );
        // Last resort: use default list
        await _loadDefaultRecommendations();
      }
    } catch (e) {
      debugPrint('Error building recommendations: $e');
      // Final fallback
      await _loadDefaultRecommendations();
    }
  }

  /// Load default recommendations (popular countries) - ensures exactly 6 with quality filter
  Future<void> _loadDefaultRecommendations() async {
    try {
      debugPrint('Loading default recommendations (fallback)...');
      final defaultCodes = [
        'FR',
        'IT',
        'ES',
        'TR',
        'AE',
        'SA',
        'GB',
        'DE',
        'US',
        'JP',
      ]; // Popular countries

      // Exclude user country if known
      final codesToFetch =
          defaultCodes
              .where(
                (code) => _userCountry == null || code != _userCountry!.cca2,
              )
              .take(6)
              .toList();

      _recommended = await _repository.getCountriesByCodes(codesToFetch);

      // Apply quality filter
      _recommended = _recommended.where((c) => _isQualityCountry(c)).toList();

      // Ensure exactly 6
      if (_recommended.length > 6) {
        _recommended = _recommended.take(6).toList();
      } else if (_recommended.length < 6) {
        // Try to get more from extended list
        final extendedCodes = ['CA', 'AU', 'NZ', 'BR', 'MX', 'IN', 'TH', 'SG'];
        final existingCodes =
            _recommended
                .map((c) => c.cca2)
                .where((code) => code != null)
                .cast<String>()
                .toSet();
        if (_userCountry?.cca2 != null) {
          existingCodes.add(_userCountry!.cca2!);
        }

        final additionalCodes =
            extendedCodes
                .where((code) => !existingCodes.contains(code))
                .take(6 - _recommended.length)
                .toList();

        if (additionalCodes.isNotEmpty) {
          try {
            final additional = await _repository.getCountriesByCodes(
              additionalCodes,
            );
            final qualityAdditional =
                additional
                    .where((country) => _isQualityCountry(country))
                    .toList();
            _recommended.addAll(qualityAdditional);
            _recommended = _recommended.take(6).toList();
          } catch (e) {
            debugPrint('Error loading additional default countries: $e');
          }
        }
      }

      debugPrint('Loaded ${_recommended.length} default recommendations');
    } catch (e) {
      debugPrint('Error loading default recommendations: $e');
      _recommended = [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
