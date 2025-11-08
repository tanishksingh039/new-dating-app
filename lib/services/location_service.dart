import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle location-based operations
class LocationService {
  // Reference point: GHS (Government High School)
  static const double referenceLatitude = 30.8635530;
  static const double referenceLongitude = 77.1209067;
  static const double allowedRadiusInKm = 2.0; // 2 km radius

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
      return false;
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return null;
      }

      // Check/request permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Location permission not granted');
        }
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Calculate distance between two coordinates in meters
  double calculateDistance({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
  }

  /// Check if user is within specified radius
  Future<bool> isUserWithinRadius({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    required double radiusInKm,
  }) async {
    double distanceInMeters = calculateDistance(
      userLat: userLat,
      userLng: userLng,
      targetLat: targetLat,
      targetLng: targetLng,
    );

    double radiusInMeters = radiusInKm * 1000;

    if (kDebugMode) {
      print('Distance: ${distanceInMeters.toStringAsFixed(2)} meters');
      print('Allowed radius: ${radiusInMeters.toStringAsFixed(2)} meters');
      print('Within radius: ${distanceInMeters <= radiusInMeters}');
    }

    return distanceInMeters <= radiusInMeters;
  }

  /// Check if user is within the allowed login radius (2km from GHS)
  Future<LocationCheckResult> checkLoginLocation() async {
    try {
      // Get current location
      Position? position = await getCurrentLocation();

      if (position == null) {
        return LocationCheckResult(
          isAllowed: false,
          errorMessage: 'Unable to get your location. Please enable location services.',
          distanceInMeters: null,
        );
      }

      // Calculate distance from reference point
      double distanceInMeters = calculateDistance(
        userLat: position.latitude,
        userLng: position.longitude,
        targetLat: referenceLatitude,
        targetLng: referenceLongitude,
      );

      double distanceInKm = distanceInMeters / 1000;
      bool isWithinRadius = distanceInKm <= allowedRadiusInKm;

      if (kDebugMode) {
        print('User location: ${position.latitude}, ${position.longitude}');
        print('Reference point: $referenceLatitude, $referenceLongitude');
        print('Distance: ${distanceInKm.toStringAsFixed(2)} km');
        print('Allowed: $isWithinRadius');
      }

      if (!isWithinRadius) {
        return LocationCheckResult(
          isAllowed: false,
          errorMessage:
              'You are ${distanceInKm.toStringAsFixed(2)} km away from the allowed location.\n'
              'You must be within ${allowedRadiusInKm.toStringAsFixed(0)} km to login.',
          distanceInMeters: distanceInMeters,
        );
      }

      return LocationCheckResult(
        isAllowed: true,
        errorMessage: null,
        distanceInMeters: distanceInMeters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking login location: $e');
      }
      return LocationCheckResult(
        isAllowed: false,
        errorMessage: 'Error checking location: $e',
        distanceInMeters: null,
      );
    }
  }

  /// Open app settings for location permission
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

/// Result of location check
class LocationCheckResult {
  final bool isAllowed;
  final String? errorMessage;
  final double? distanceInMeters;

  LocationCheckResult({
    required this.isAllowed,
    this.errorMessage,
    this.distanceInMeters,
  });

  double? get distanceInKm =>
      distanceInMeters != null ? distanceInMeters! / 1000 : null;
}
