import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle location-based operations
class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Default values (fallback if admin settings not available)
  static const double _defaultReferenceLatitude = 30.8635530;
  static const double _defaultReferenceLongitude = 77.1209067;
  static const double _defaultAllowedRadiusInKm = 2.0;
  
  // Cached settings
  double? _cachedLatitude;
  double? _cachedLongitude;
  double? _cachedRadius;
  bool? _cachedLocationRestrictionEnabled;
  DateTime? _lastFetchTime;
  
  /// Fetch geolocation settings from Firestore admin settings
  Future<Map<String, dynamic>> _getGeolocationSettings() async {
    try {
      // Cache for 5 minutes to avoid excessive Firestore reads
      if (_lastFetchTime != null && 
          DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
        return {
          'latitude': _cachedLatitude ?? _defaultReferenceLatitude,
          'longitude': _cachedLongitude ?? _defaultReferenceLongitude,
          'radius': _cachedRadius ?? _defaultAllowedRadiusInKm,
          'enabled': _cachedLocationRestrictionEnabled ?? true,
        };
      }
      
      final doc = await _firestore
          .collection('admin_settings')
          .doc('app_settings')
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        _cachedLatitude = (data?['referenceLatitude'] ?? _defaultReferenceLatitude).toDouble();
        _cachedLongitude = (data?['referenceLongitude'] ?? _defaultReferenceLongitude).toDouble();
        _cachedRadius = (data?['allowedRadiusInKm'] ?? _defaultAllowedRadiusInKm).toDouble();
        _cachedLocationRestrictionEnabled = data?['locationRestrictionEnabled'] ?? true;
        _lastFetchTime = DateTime.now();
        
        if (kDebugMode) {
          print('[LocationService] Settings loaded from Firestore:');
          print('[LocationService] Latitude: $_cachedLatitude');
          print('[LocationService] Longitude: $_cachedLongitude');
          print('[LocationService] Radius: $_cachedRadius km');
          print('[LocationService] Enabled: $_cachedLocationRestrictionEnabled');
        }
      } else {
        if (kDebugMode) {
          print('[LocationService] No admin settings found, using defaults');
        }
        _cachedLatitude = _defaultReferenceLatitude;
        _cachedLongitude = _defaultReferenceLongitude;
        _cachedRadius = _defaultAllowedRadiusInKm;
        _cachedLocationRestrictionEnabled = true;
        _lastFetchTime = DateTime.now();
      }
      
      return {
        'latitude': _cachedLatitude!,
        'longitude': _cachedLongitude!,
        'radius': _cachedRadius!,
        'enabled': _cachedLocationRestrictionEnabled!,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[LocationService] Error fetching settings: $e');
        print('[LocationService] Using default values');
      }
      return {
        'latitude': _defaultReferenceLatitude,
        'longitude': _defaultReferenceLongitude,
        'radius': _defaultAllowedRadiusInKm,
        'enabled': true,
      };
    }
  }

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

  /// Check if user is within the allowed login radius (checks multiple campus locations)
  Future<LocationCheckResult> checkLoginLocation() async {
    try {
      // Get geolocation settings from admin panel
      final settings = await _getGeolocationSettings();
      final locationRestrictionEnabled = settings['enabled'] as bool;
      
      // If location restriction is disabled, allow access
      if (!locationRestrictionEnabled) {
        if (kDebugMode) {
          print('[LocationService] Location restriction is disabled, allowing access');
        }
        return LocationCheckResult(
          isAllowed: true,
          errorMessage: null,
          distanceInMeters: null,
        );
      }
      
      // Get current location
      Position? position = await getCurrentLocation();

      if (position == null) {
        return LocationCheckResult(
          isAllowed: false,
          errorMessage: 'Unable to get your location. Please enable location services.',
          distanceInMeters: null,
        );
      }

      // Check against multiple campus locations
      final campusLocationsSnapshot = await _firestore
          .collection('campus_locations')
          .where('isActive', isEqualTo: true)
          .get();

      if (campusLocationsSnapshot.docs.isEmpty) {
        // Fallback to single location from admin settings
        if (kDebugMode) {
          print('[LocationService] No campus locations found, using fallback settings');
        }
        return await _checkSingleLocation(
          position,
          settings['latitude'] as double,
          settings['longitude'] as double,
          settings['radius'] as double,
        );
      }

      // Check if user is within any of the active campus locations
      double? closestDistance;
      String? closestCampusName;

      for (var doc in campusLocationsSnapshot.docs) {
        final data = doc.data();
        final campusLat = (data['latitude'] as num).toDouble();
        final campusLng = (data['longitude'] as num).toDouble();
        final campusRadius = (data['radiusInKm'] as num).toDouble();
        final campusName = data['name'] as String;

        final distanceInMeters = calculateDistance(
          userLat: position.latitude,
          userLng: position.longitude,
          targetLat: campusLat,
          targetLng: campusLng,
        );

        final distanceInKm = distanceInMeters / 1000;

        if (kDebugMode) {
          print('[LocationService] Checking campus: $campusName');
          print('[LocationService] Distance: ${distanceInKm.toStringAsFixed(2)} km');
          print('[LocationService] Allowed radius: ${campusRadius.toStringAsFixed(2)} km');
        }

        // Track closest campus
        if (closestDistance == null || distanceInMeters < closestDistance) {
          closestDistance = distanceInMeters;
          closestCampusName = campusName;
        }

        // If within any campus radius, allow access
        if (distanceInKm <= campusRadius) {
          if (kDebugMode) {
            print('[LocationService] ✅ User is within $campusName radius');
          }
          return LocationCheckResult(
            isAllowed: true,
            errorMessage: null,
            distanceInMeters: distanceInMeters,
          );
        }
      }

      // User is not within any campus location
      final closestDistanceKm = closestDistance! / 1000;
      if (kDebugMode) {
        print('[LocationService] ❌ User not within any campus location');
        print('[LocationService] Closest campus: $closestCampusName (${closestDistanceKm.toStringAsFixed(2)} km)');
      }

      return LocationCheckResult(
        isAllowed: false,
        errorMessage:
            'You are ${closestDistanceKm.toStringAsFixed(2)} km away from the nearest campus ($closestCampusName).\n'
            'You must be within an allowed campus area to login.',
        distanceInMeters: closestDistance,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[LocationService] Error checking login location: $e');
      }
      return LocationCheckResult(
        isAllowed: false,
        errorMessage: 'Error checking location: $e',
        distanceInMeters: null,
      );
    }
  }

  /// Helper method to check against a single location (fallback)
  Future<LocationCheckResult> _checkSingleLocation(
    Position position,
    double referenceLatitude,
    double referenceLongitude,
    double allowedRadiusInKm,
  ) async {
    final distanceInMeters = calculateDistance(
      userLat: position.latitude,
      userLng: position.longitude,
      targetLat: referenceLatitude,
      targetLng: referenceLongitude,
    );

    final distanceInKm = distanceInMeters / 1000;
    final isWithinRadius = distanceInKm <= allowedRadiusInKm;

    if (kDebugMode) {
      print('[LocationService] User location: ${position.latitude}, ${position.longitude}');
      print('[LocationService] Reference point: $referenceLatitude, $referenceLongitude');
      print('[LocationService] Distance: ${distanceInKm.toStringAsFixed(2)} km');
      print('[LocationService] Allowed radius: ${allowedRadiusInKm.toStringAsFixed(2)} km');
      print('[LocationService] Within radius: $isWithinRadius');
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
