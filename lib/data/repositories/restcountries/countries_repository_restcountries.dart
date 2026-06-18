import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/country.dart';
import '../countries_repository.dart';

class CountriesRepositoryRestCountries implements CountriesRepository {
  static const String _baseUrl = 'restcountries.com';
  static const String _apiVersion = 'v3.1';

  // Fields to request to reduce payload (max 10 fields per API docs)
  // Includes languages and currencies for full country details
  static const String _fieldsParam =
      'name,flags,capital,region,subregion,population,languages,currencies,cca2,cca3';

  @override
  Future<List<Country>> getAllCountries() async {
    try {
      debugPrint('REST Countries: Fetching all countries...');
      final url = Uri.https(_baseUrl, '/$_apiVersion/all', {
        'fields': _fieldsParam,
      });

      debugPrint('REST Countries URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('REST Countries: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint('REST Countries Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data =
              json.decode(response.body) as List<dynamic>;
          final countries =
              data
                  .map((json) => Country.fromJson(json as Map<String, dynamic>))
                  .toList();
          debugPrint(
            'REST Countries: Successfully loaded ${countries.length} countries',
          );
          return countries;
        } catch (e, stackTrace) {
          debugPrint('REST Countries: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse countries data: $e');
        }
      } else {
        debugPrint('REST Countries: Error Status ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
        throw Exception(
          'Failed to load countries: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REST Countries: Error getting all countries: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting all countries: $e');
    }
  }

  @override
  Future<Country> getCountryByName(String name) async {
    try {
      debugPrint('REST Countries: Fetching country by name: $name');
      final url = Uri.https(_baseUrl, '/$_apiVersion/name/$name', {
        'fullText': 'true',
        'fields': _fieldsParam,
      });

      debugPrint('REST Countries URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('REST Countries: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint('REST Countries Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data =
              json.decode(response.body) as List<dynamic>;
          if (data.isEmpty) {
            throw Exception('Country not found: $name');
          }
          final country = Country.fromJson(data.first as Map<String, dynamic>);
          debugPrint(
            'REST Countries: Successfully loaded country: ${country.nameCommon}',
          );
          return country;
        } catch (e, stackTrace) {
          debugPrint('REST Countries: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse country data: $e');
        }
      } else {
        debugPrint('REST Countries: Error Status ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
        throw Exception(
          'Failed to load country: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REST Countries: Error getting country by name: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting country by name: $e');
    }
  }

  @override
  Future<Country> getCountryByCode(String code) async {
    try {
      debugPrint('REST Countries: Fetching country by code: $code');
      // Use standard fields (borders not needed anymore for recommendations)
      final url = Uri.https(_baseUrl, '/$_apiVersion/alpha/$code', {
        'fields': _fieldsParam,
      });

      debugPrint('REST Countries URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('REST Countries: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint('REST Countries Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final country = Country.fromJson(data);
          debugPrint(
            'REST Countries: Successfully loaded country: ${country.nameCommon}',
          );
          return country;
        } catch (e, stackTrace) {
          debugPrint('REST Countries: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse country data: $e');
        }
      } else {
        debugPrint('REST Countries: Error Status ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
        throw Exception(
          'Failed to load country: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REST Countries: Error getting country by code: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting country by code: $e');
    }
  }

  @override
  Future<List<Country>> getCountriesByCodes(List<String> codes) async {
    try {
      if (codes.isEmpty) return [];

      debugPrint('REST Countries: Fetching countries by codes: $codes');
      // REST Countries API uses comma-separated codes (not semicolons)
      final codesParam = codes.join(',');
      final url = Uri.https(_baseUrl, '/$_apiVersion/alpha', {
        'codes': codesParam,
        'fields': _fieldsParam,
      });

      debugPrint('REST Countries URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('REST Countries: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint('REST Countries Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data =
              json.decode(response.body) as List<dynamic>;
          final countries =
              data
                  .map((json) => Country.fromJson(json as Map<String, dynamic>))
                  .toList();
          debugPrint(
            'REST Countries: Successfully loaded ${countries.length} countries',
          );
          return countries;
        } catch (e, stackTrace) {
          debugPrint('REST Countries: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse countries data: $e');
        }
      } else {
        debugPrint('REST Countries: Error Status ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
        throw Exception(
          'Failed to load countries: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REST Countries: Error getting countries by codes: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting countries by codes: $e');
    }
  }

  /// Get countries by region
  Future<List<Country>> getCountriesByRegion(String region) async {
    try {
      debugPrint('REST Countries: Fetching countries by region: $region');
      final url = Uri.https(_baseUrl, '/$_apiVersion/region/$region', {
        'fields': _fieldsParam,
      });

      debugPrint('REST Countries URL: $url');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('REST Countries: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint('REST Countries Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data =
              json.decode(response.body) as List<dynamic>;
          final countries =
              data
                  .map((json) => Country.fromJson(json as Map<String, dynamic>))
                  .toList();
          debugPrint(
            'REST Countries: Successfully loaded ${countries.length} countries from region $region',
          );
          return countries;
        } catch (e, stackTrace) {
          debugPrint('REST Countries: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse countries data: $e');
        }
      } else {
        debugPrint('REST Countries: Error Status ${response.statusCode}');
        debugPrint('Error Response: ${response.body}');
        throw Exception(
          'Failed to load countries: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('REST Countries: Error getting countries by region: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting countries by region: $e');
    }
  }
}
