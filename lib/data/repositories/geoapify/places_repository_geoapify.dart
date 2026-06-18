import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/place.dart';
import '../places_repository.dart';
import '../../services/location_service.dart';
import '../../constants/geoapify_category_map.dart';

class PlacesRepositoryGeoapify implements PlacesRepository {
  static String get _apiKey {
    const key = String.fromEnvironment('GEOAPIFY_API_KEY');
    if (key.isEmpty) {
      throw StateError(
        'Missing GEOAPIFY_API_KEY. Run Flutter with --dart-define=GEOAPIFY_API_KEY=your-key.',
      );
    }
    return key;
  }

  // Testing constants for Cairo, Egypt
  static const double kCairoLat = 30.0444;
  static const double kCairoLon = 31.2357;

  // Set to true only when demoing the app with fixed Cairo coordinates.
  static const bool kForceCairoForTesting = false;

  // Cairo radius (25km to cover Cairo + Giza area)
  static const int kCairoRadiusMeters = 25000;

  final LocationService _locationService = LocationService();

  // Convert Geoapify categories to app categories
  static String _mapGeoapifyCategoryToAppCategory(String geoapifyCategory) {
    // Normalize the category string (remove any extra whitespace)
    final normalized = geoapifyCategory.trim();

    // Check all app categories
    for (final appCategory in GeoapifyCategoryMap.getAvailableCategories()) {
      final geoapifyCats = GeoapifyCategoryMap.geoapifyCategoriesFor(
        appCategory,
      );
      if (geoapifyCats.contains(normalized)) {
        debugPrint('    Category mapping: "$normalized" -> $appCategory');
        return appCategory;
      }
    }

    debugPrint('    Category mapping: "$normalized" -> Other (no match found)');
    return 'Other';
  }

  // Get all Geoapify categories from app categories (now receives Geoapify categories directly)
  static List<String> _getGeoapifyCategories(List<String> categories) {
    // Categories are already Geoapify categories from the mapping
    return categories;
  }

  @override
  Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
    required List<String> categories,
    int radiusMeters = 3000,
    int limit = 20,
  }) async {
    try {
      // Use Cairo coordinates if testing flag is enabled
      final double finalLat = kForceCairoForTesting ? kCairoLat : lat;
      final double finalLon = kForceCairoForTesting ? kCairoLon : lon;
      final int finalRadius =
          kForceCairoForTesting ? kCairoRadiusMeters : radiusMeters;

      if (kForceCairoForTesting) {
        debugPrint(
          '🧪 TESTING MODE: Using Cairo coordinates (lat=$finalLat, lon=$finalLon, radius=${finalRadius}m)',
        );
      }

      // Filter out unsupported categories before making API call
      final filteredCategories = GeoapifyCategoryMap.filterSupportedCategories(
        categories,
      );
      final geoapifyCategories = _getGeoapifyCategories(filteredCategories);

      if (geoapifyCategories.isEmpty) {
        debugPrint(
          'No Geoapify categories found for: $categories (after filtering)',
        );
        return [];
      }

      // Log if any categories were filtered out
      if (filteredCategories.length != categories.length) {
        final removed =
            categories.where((c) => !filteredCategories.contains(c)).toList();
        debugPrint('⚠️ Filtered out unsupported categories: $removed');
      }

      // Build request parameters - IMPORTANT: longitude first in filter and bias
      final categoriesParam = geoapifyCategories.join(',');
      final filter =
          'circle:$finalLon,$finalLat,$finalRadius'; // lon,lat,radius
      final bias = 'proximity:$finalLon,$finalLat'; // lon,lat

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('GEOAPIFY API DEBUG: Request Parameters');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint(
        'Location: lat=$finalLat, lon=$finalLon ${kForceCairoForTesting ? "(Cairo - Testing)" : "(Device)"}',
      );
      debugPrint('Categories (Geoapify): $geoapifyCategories');
      debugPrint('Categories param: $categoriesParam');
      debugPrint('Filter: $filter (format: circle:lon,lat,radius)');
      debugPrint('Bias: $bias (format: proximity:lon,lat)');
      debugPrint('Radius: $finalRadius meters');
      debugPrint('Limit: $limit');

      // Build URL with proper encoding using queryParameters
      final url = Uri.https('api.geoapify.com', '/v2/places', {
        'categories': categoriesParam,
        'filter': filter,
        'bias': bias,
        'limit': limit.toString(),
        'apiKey': _apiKey,
      });

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('GEOAPIFY API DEBUG - STEP 1: Final Request URL');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Endpoint: https://api.geoapify.com/v2/places');
      debugPrint('Request URL omitted because it contains the API key.');
      debugPrint('═══════════════════════════════════════════════════════');

      // STEP 2: Check HTTP response
      debugPrint('GEOAPIFY API DEBUG - STEP 2: Making HTTP Request...');
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint(
                'GEOAPIFY API DEBUG - Request timed out after 30 seconds',
              );
              throw Exception('Request timeout');
            },
          );

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('GEOAPIFY API DEBUG - STEP 2: HTTP Response');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');

      final responseBody = response.body;
      debugPrint('Response Body Length: ${responseBody.length} characters');

      final previewLength =
          responseBody.length > 500 ? 500 : responseBody.length;
      debugPrint('Response Body (first $previewLength chars):');
      debugPrint(responseBody.substring(0, previewLength));
      if (responseBody.length > 500) {
        debugPrint('... (truncated, full length: ${responseBody.length})');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      // STEP 3: Handle response based on status code
      if (response.statusCode == 200) {
        debugPrint('GEOAPIFY API DEBUG - STEP 3: Parsing JSON Response...');
        try {
          final data = json.decode(responseBody) as Map<String, dynamic>;

          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('GEOAPIFY API DEBUG - STEP 3: JSON Structure');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('Top-level keys: ${data.keys.toList()}');

          // Check for API error in response
          if (data.containsKey('message') || data.containsKey('error')) {
            final errorMsg =
                data['message'] ?? data['error'] ?? 'Unknown API error';
            debugPrint('❌ API returned error in response: $errorMsg');
            debugPrint('Full error data: $data');
            throw Exception('API Error: $errorMsg');
          }

          // Verify features array exists
          if (!data.containsKey('features')) {
            debugPrint('❌ Response missing "features" key');
            debugPrint('Available keys: ${data.keys.toList()}');
            debugPrint('Full response: $data');
            throw Exception('API response missing features array');
          }

          final places = _parsePlacesFromResponse(data, finalLat, finalLon);
          debugPrint('✅ Successfully parsed ${places.length} places from API');
          debugPrint('═══════════════════════════════════════════════════════');
          return places;
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing API response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse API response: $e');
        }
      } else {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('GEOAPIFY API DEBUG - STEP 3: HTTP Error');
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('❌ Status Code: ${response.statusCode} (expected 200)');
        debugPrint('Error Response Body: $responseBody');
        debugPrint('═══════════════════════════════════════════════════════');
        throw Exception(
          'Failed to load places: HTTP ${response.statusCode} - $responseBody',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting nearby places: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting nearby places: $e');
    }
  }

  @override
  Future<List<Place>> searchPlacesByText({
    required String text,
    required List<String> categories,
    required double biasLat,
    required double biasLon,
    int limit = 20,
  }) async {
    try {
      // Use Cairo coordinates if testing flag is enabled
      final double finalBiasLat = kForceCairoForTesting ? kCairoLat : biasLat;
      final double finalBiasLon = kForceCairoForTesting ? kCairoLon : biasLon;

      if (kForceCairoForTesting) {
        debugPrint(
          '🧪 TESTING MODE: Using Cairo coordinates for search bias (lat=$finalBiasLat, lon=$finalBiasLon)',
        );
      }

      // Filter out unsupported categories before making API call
      final filteredCategories = GeoapifyCategoryMap.filterSupportedCategories(
        categories,
      );
      final geoapifyCategories = _getGeoapifyCategories(filteredCategories);

      if (geoapifyCategories.isEmpty) {
        debugPrint(
          'No Geoapify categories found for search: $categories (after filtering)',
        );
        return [];
      }

      // Log if any categories were filtered out
      if (filteredCategories.length != categories.length) {
        final removed =
            categories.where((c) => !filteredCategories.contains(c)).toList();
        debugPrint(
          '⚠️ Filtered out unsupported categories from search: $removed',
        );
      }

      // Build request parameters - IMPORTANT: longitude first in bias
      final categoriesParam = geoapifyCategories.join(',');
      final bias = 'proximity:$finalBiasLon,$finalBiasLat'; // lon,lat

      debugPrint('Search query: $text');
      debugPrint('Categories: $geoapifyCategories');
      debugPrint(
        'Bias: $bias (format: proximity:lon,lat) ${kForceCairoForTesting ? "(Cairo - Testing)" : "(Device)"}',
      );

      // Build URL with proper encoding
      final url = Uri.https('api.geoapify.com', '/v2/places', {
        'text': text,
        'categories': categoriesParam,
        'bias': bias,
        'limit': limit.toString(),
        'apiKey': _apiKey,
      });

      debugPrint('Search endpoint: https://api.geoapify.com/v2/places');

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('Search request timed out after 30 seconds');
              throw Exception('Request timeout');
            },
          );

      debugPrint('Search response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;

          // Check for API error in response
          if (data.containsKey('message') || data.containsKey('error')) {
            final errorMsg =
                data['message'] ?? data['error'] ?? 'Unknown API error';
            debugPrint('❌ API returned error in search response: $errorMsg');
            throw Exception('API Error: $errorMsg');
          }

          // Verify features array exists
          if (!data.containsKey('features')) {
            debugPrint('❌ Search response missing "features" key');
            throw Exception('API response missing features array');
          }

          final places = _parsePlacesFromResponse(
            data,
            finalBiasLat,
            finalBiasLon,
          );
          debugPrint(
            '✅ Successfully parsed ${places.length} places from search',
          );
          return places;
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing search response: $e');
          debugPrint('Stack trace: $stackTrace');
          throw Exception('Failed to parse API response: $e');
        }
      } else {
        debugPrint('❌ Search Status Code: ${response.statusCode}');
        debugPrint('Error Response Body: ${response.body}');
        throw Exception(
          'Failed to search places: HTTP ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error searching places: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error searching places: $e');
    }
  }

  List<Place> _parsePlacesFromResponse(
    Map<String, dynamic> data,
    double userLat,
    double userLon,
  ) {
    debugPrint('GEOAPIFY API DEBUG - STEP 4: Parsing Places from Features');
    debugPrint('═══════════════════════════════════════════════════════');

    final List<Place> places = [];

    // Check if data has features
    if (!data.containsKey('features')) {
      debugPrint(
        '❌ API response missing features key. Data keys: ${data.keys}',
      );
      return [];
    }

    final features = data['features'] as List<dynamic>? ?? [];
    debugPrint('Found ${features.length} features in API response');

    for (int i = 0; i < features.length; i++) {
      final feature = features[i];
      debugPrint('Parsing feature $i/${features.length}...');

      final properties = feature['properties'] as Map<String, dynamic>?;
      if (properties == null) {
        debugPrint('  ⚠️ Feature $i has no properties, skipping');
        continue;
      }

      debugPrint('  Feature $i properties keys: ${properties.keys.toList()}');

      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      double? lat;
      double? lon;

      if (coordinates != null && coordinates.length >= 2) {
        lon = (coordinates[0] as num).toDouble();
        lat = (coordinates[1] as num).toDouble();
      }

      final placeId =
          properties['place_id'] as String? ??
          properties['osm_id']?.toString() ??
          'place_${places.length}';
      final name =
          properties['name'] as String? ??
          properties['name_en'] as String? ??
          'Unknown';
      // Map Geoapify categories to app categories
      final categories = properties['categories'] as List<dynamic>? ?? [];
      String appCategory = 'Other';

      debugPrint('  Raw categories from API: $categories');

      // Try to find a matching category from the list
      for (final cat in categories) {
        final catString = cat.toString().trim();
        debugPrint('    Checking category: "$catString"');
        final mapped = _mapGeoapifyCategoryToAppCategory(catString);
        if (mapped != 'Other') {
          appCategory = mapped;
          debugPrint('    ✅ Matched! Using category: $appCategory');
          break; // Use the first matching category
        }
      }

      if (appCategory == 'Other') {
        debugPrint('    ⚠️ No category match found, using "Other"');
      }

      // Skip if name is still Unknown (invalid place)
      if (name == 'Unknown' && placeId.isEmpty) {
        debugPrint('Skipping place with no name or ID');
        continue;
      }

      // Extract rating if available
      // Note: Geoapify Places API v2 does NOT provide ratings
      // This is a limitation of the free API
      double? rating;
      if (properties.containsKey('rating')) {
        rating = (properties['rating'] as num?)?.toDouble();
        debugPrint('    Found rating: $rating');
      } else {
        // Check alternative locations for rating
        if (properties.containsKey('details') && properties['details'] is Map) {
          final details = properties['details'] as Map<String, dynamic>;
          if (details.containsKey('rating')) {
            rating = (details['rating'] as num?)?.toDouble();
            debugPrint('    Found rating in details: $rating');
          }
        }
        if (rating == null) {
          debugPrint('    ⚠️ No rating available (Geoapify API limitation)');
        }
      }

      // Extract address
      final address =
          properties['formatted'] as String? ??
          properties['address_line2'] as String?;

      // Extract phone
      final phone = properties['contact']?['phone'] as String?;

      // Extract website
      final website = properties['website'] as String?;

      // Extract opening hours
      String? openingHours;
      if (properties.containsKey('opening_hours')) {
        final hours = properties['opening_hours'];
        if (hours is Map && hours.containsKey('open_now')) {
          openingHours = hours['open_now'] == true ? 'Open now' : 'Closed';
        }
      }

      // Calculate distance
      double? distance;
      if (lat != null && lon != null) {
        final userLocation = PlaceLocation(
          latitude: userLat,
          longitude: userLon,
        );
        final placeLocation = PlaceLocation(latitude: lat, longitude: lon);
        distance = userLocation.distanceTo(placeLocation);
      }

      // Extract photos (if available)
      // Note: Geoapify Places API v2 does NOT provide photos/images
      // This is a limitation of the free API
      final List<String> photos = [];

      // Check multiple possible image fields
      if (properties.containsKey('image')) {
        final image = properties['image'];
        if (image is String) {
          photos.add(image);
          debugPrint('    Found image: $image');
        } else if (image is List) {
          photos.addAll(image.map((e) => e.toString()));
          debugPrint('    Found images: $photos');
        }
      }

      // Check alternative image locations
      if (photos.isEmpty) {
        if (properties.containsKey('photos') && properties['photos'] is List) {
          final photosList = properties['photos'] as List;
          photos.addAll(photosList.map((e) => e.toString()));
          debugPrint('    Found photos: $photos');
        } else if (properties.containsKey('thumbnail')) {
          photos.add(properties['thumbnail'] as String);
          debugPrint('    Found thumbnail: ${photos[0]}');
        } else if (properties.containsKey('preview')) {
          photos.add(properties['preview'] as String);
          debugPrint('    Found preview: ${photos[0]}');
        } else {
          debugPrint('    ⚠️ No photos available (Geoapify API limitation)');
        }
      }

      final place = Place(
        id: placeId,
        name: name,
        category: appCategory,
        rating: rating,
        photos: photos,
        openingHours: openingHours,
        location:
            lat != null && lon != null
                ? PlaceLocation(latitude: lat, longitude: lon)
                : null,
        description: properties['description'] as String?,
        city: properties['city'] as String?,
        country: properties['country'] as String?,
        address: address,
        phone: phone,
        website: website,
        distance: distance,
      );

      places.add(place);
      debugPrint('  ✅ Place $i parsed: ${place.name} (${place.category})');
    }

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('STEP 4 COMPLETE: Parsed ${places.length} places total');
    debugPrint('═══════════════════════════════════════════════════════');
    return places;
  }

  // Legacy methods - delegate to mock or return empty
  @override
  Future<List<Place>> getPlacesByCity(String city) async {
    // For now, return empty - can be enhanced later
    return [];
  }

  @override
  Future<List<Place>> getPlacesByCategory(String category) async {
    // Get current location and use nearby places
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      return getNearbyPlaces(
        lat: location['latitude']!,
        lon: location['longitude']!,
        categories: [category],
      );
    }
    return [];
  }

  @override
  Future<List<Place>> getPlacesByInterests(List<String> interests) async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      return getNearbyPlaces(
        lat: location['latitude']!,
        lon: location['longitude']!,
        categories: interests,
      );
    }
    return [];
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      return searchPlacesByText(
        text: query,
        categories: ['Food', 'Shopping', 'Nature', 'Ancient', 'Medical'],
        biasLat: location['latitude']!,
        biasLon: location['longitude']!,
      );
    }
    return [];
  }

  @override
  Future<Place?> getPlaceById(String placeId) async {
    // Geoapify doesn't have a direct get by ID endpoint
    // Would need to search or cache places
    return null;
  }

  @override
  Future<List<Place>> getRecommendedPlaces({
    String? city,
    List<String>? interests,
    int? limit,
  }) async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      return getNearbyPlaces(
        lat: location['latitude']!,
        lon: location['longitude']!,
        categories: interests ?? ['Food', 'Shopping', 'Nature', 'Ancient'],
        limit: limit ?? 10,
      );
    }
    return [];
  }

  @override
  Future<List<String>> getCitiesByCountry(String country) async {
    // Not available in Geoapify - return empty
    return [];
  }
}
