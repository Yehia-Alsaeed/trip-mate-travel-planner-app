import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to get country code from coordinates using Geoapify reverse geocoding
class ReverseGeocodingService {
  static String get _apiKey {
    const key = String.fromEnvironment('GEOAPIFY_API_KEY');
    if (key.isEmpty) {
      throw StateError(
        'Missing GEOAPIFY_API_KEY. Run Flutter with --dart-define=GEOAPIFY_API_KEY=your-key.',
      );
    }
    return key;
  }
  static const String _baseUrl = 'api.geoapify.com';

  /// Get country code (ISO2) from latitude and longitude
  /// Returns null if unable to determine country
  Future<String?> getCountryCode({
    required double lat,
    required double lon,
  }) async {
    try {
      debugPrint(
        'ReverseGeocodingService: Getting country code for lat=$lat, lon=$lon',
      );

      final url = Uri.https(_baseUrl, '/v1/geocode/reverse', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'type': 'country',
        'apiKey': _apiKey,
      });

      debugPrint(
        'ReverseGeocodingService endpoint: https://$_baseUrl/v1/geocode/reverse',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('ReverseGeocodingService: Request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint(
        'ReverseGeocodingService Response Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;

          // Check for features array
          if (!data.containsKey('features')) {
            debugPrint('ReverseGeocodingService: No features in response');
            return null;
          }

          final features = data['features'] as List<dynamic>? ?? [];
          if (features.isEmpty) {
            debugPrint('ReverseGeocodingService: Empty features array');
            return null;
          }

          // Get first feature properties
          final firstFeature = features.first as Map<String, dynamic>;
          final properties =
              firstFeature['properties'] as Map<String, dynamic>?;

          if (properties == null) {
            debugPrint('ReverseGeocodingService: No properties in feature');
            return null;
          }

          // Try to get country code (ISO2)
          final countryCode =
              properties['country_code'] as String? ??
              properties['iso_code'] as String? ??
              properties['country'] as String?;

          if (countryCode != null) {
            // Ensure it's uppercase and 2 characters (ISO2)
            final code = countryCode.toUpperCase();
            if (code.length == 2) {
              debugPrint('ReverseGeocodingService: Found country code: $code');
              return code;
            } else if (code.length == 3) {
              // If we got ISO3, we'd need to convert, but for now return null
              debugPrint(
                'ReverseGeocodingService: Got ISO3 code, need conversion: $code',
              );
              return null;
            }
          }

          debugPrint(
            'ReverseGeocodingService: No country code found in properties',
          );
          debugPrint('Available properties: ${properties.keys.toList()}');
          return null;
        } catch (e, stackTrace) {
          debugPrint('ReverseGeocodingService: Error parsing response: $e');
          debugPrint('Stack trace: $stackTrace');
          return null;
        }
      } else {
        debugPrint(
          'ReverseGeocodingService: Error Status ${response.statusCode}',
        );
        debugPrint('Error Response: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('ReverseGeocodingService: Error getting country code: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}
