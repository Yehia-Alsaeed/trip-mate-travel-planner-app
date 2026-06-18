import '../models/country.dart';

/// Abstract repository for countries data
abstract class CountriesRepository {
  /// Get all countries (with fields filter to reduce payload)
  Future<List<Country>> getAllCountries();

  /// Get a country by name (full text search)
  Future<Country> getCountryByName(String name);

  /// Get a country by ISO code (alpha-2 or alpha-3)
  Future<Country> getCountryByCode(String code);

  /// Get multiple countries by ISO codes
  Future<List<Country>> getCountriesByCodes(List<String> codes);

  /// Get countries by region
  Future<List<Country>> getCountriesByRegion(String region);
}
