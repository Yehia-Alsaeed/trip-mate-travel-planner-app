import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position - FAST version: prioritize lastKnown, use low accuracy, short timeout
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('LocationService: Starting fast location fetch...');

      // Step 1: Try getLastKnownPosition FIRST (fastest)
      debugPrint('LocationService: Trying getLastKnownPosition...');
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint(
          'LocationService: ✅ Using lastKnownPosition - Lat: ${position.latitude}, Lon: ${position.longitude}',
        );
        return position;
      }
      debugPrint('LocationService: lastKnownPosition is null');

      // Step 2: Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      debugPrint('LocationService: Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint(
          'LocationService: Location services are disabled, using fallback',
        );
        return _getFallbackPosition();
      }

      // Step 3: Check permissions (quick check)
      LocationPermission permission = await checkPermission();
      debugPrint('LocationService: Current permission: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Permission denied, using fallback');
        return _getFallbackPosition();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'LocationService: Permission denied forever, using fallback',
        );
        return _getFallbackPosition();
      }

      // Step 4: Try getCurrentPosition with LOW accuracy and SHORT timeout (2 seconds)
      debugPrint(
        'LocationService: Trying getCurrentPosition (low accuracy, 2s timeout)...',
      );
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 2),
        );
        debugPrint(
          'LocationService: ✅ Using fresh position - Lat: ${position.latitude}, Lon: ${position.longitude}',
        );
        return position;
      } catch (e) {
        debugPrint(
          'LocationService: getCurrentPosition timed out or failed: $e',
        );
        debugPrint('LocationService: Using fallback position');
        return _getFallbackPosition();
      }
    } catch (e, stackTrace) {
      debugPrint('LocationService: Error getting position: $e');
      debugPrint('LocationService: Stack trace: $stackTrace');
      debugPrint('LocationService: Using fallback position');
      return _getFallbackPosition();
    }
  }

  // Fallback position (Paris, France - any valid location)
  Position _getFallbackPosition() {
    debugPrint(
      'LocationService: ⚠️ Using fallback position (Paris, France) - Lat: 48.8566, Lon: 2.3522',
    );
    return Position(
      latitude: 48.8566,
      longitude: 2.3522,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  // Get current latitude and longitude
  Future<Map<String, double>?> getCurrentLocation() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return {'latitude': position.latitude, 'longitude': position.longitude};
    }
    return null;
  }
}
