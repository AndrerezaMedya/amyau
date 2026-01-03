import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model untuk menyimpan data lokasi
class UserLocation {
  final double latitude;
  final double longitude;
  final String? cityName;
  final String? subLocality;
  final DateTime lastUpdated;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.cityName,
    this.subLocality,
    required this.lastUpdated,
  });

  /// Default location (Jakarta)
  factory UserLocation.defaultLocation() {
    return UserLocation(
      latitude: -6.2088,
      longitude: 106.8456,
      cityName: 'Jakarta',
      subLocality: null,
      lastUpdated: DateTime.now(),
    );
  }

  /// Format nama lokasi untuk display
  String get displayName {
    if (subLocality != null && cityName != null) {
      return '$subLocality, $cityName';
    }
    return cityName ?? 'Lokasi tidak diketahui';
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'cityName': cityName,
        'subLocality': subLocality,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      cityName: json['cityName'] as String?,
      subLocality: json['subLocality'] as String?,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Enum untuk status permission lokasi
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

/// Service untuk mengelola lokasi pengguna
class LocationService {
  LocationService._();

  static const String _locationKey = 'user_location';
  static const String _latKey = 'user_lat';
  static const String _lngKey = 'user_lng';
  static const String _cityKey = 'user_city';

  /// Check apakah location service tersedia
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Check status permission lokasi
  static Future<LocationPermissionStatus> checkPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      final permission = await Geolocator.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request permission lokasi
  static Future<LocationPermissionStatus> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Coba buka settings location
        await Geolocator.openLocationSettings();
        return LocationPermissionStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Buka app settings agar user bisa enable manual
        await Geolocator.openAppSettings();
        return LocationPermissionStatus.deniedForever;
      }

      return _mapPermission(permission);
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Get current location
  static Future<UserLocation?> getCurrentLocation() async {
    try {
      final permissionStatus = await checkPermission();

      if (permissionStatus != LocationPermissionStatus.granted) {
        debugPrint('Location permission not granted: $permissionStatus');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Get city name from coordinates
      String? cityName;
      String? subLocality;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          cityName = place.locality ??
              place.administrativeArea ??
              place.subAdministrativeArea;
          subLocality = place.subLocality;
          debugPrint('Location: $subLocality, $cityName');
        }
      } catch (e) {
        debugPrint('Error getting placemark: $e');
        cityName = 'Unknown';
      }

      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: cityName,
        subLocality: subLocality,
        lastUpdated: DateTime.now(),
      );

      // Save to local storage
      await _saveLocation(userLocation);

      return userLocation;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get saved location from local storage
  static Future<UserLocation?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_latKey);
      final lng = prefs.getDouble(_lngKey);
      final city = prefs.getString(_cityKey);

      if (lat != null && lng != null) {
        return UserLocation(
          latitude: lat,
          longitude: lng,
          cityName: city,
          lastUpdated: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting saved location: $e');
      return null;
    }
  }

  /// Save location to local storage
  static Future<void> _saveLocation(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, location.latitude);
      await prefs.setDouble(_lngKey, location.longitude);
      if (location.cityName != null) {
        await prefs.setString(_cityKey, location.cityName!);
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  /// Get location with fallback to saved or default
  static Future<UserLocation> getLocationWithFallback() async {
    // Try to get current location
    final current = await getCurrentLocation();
    if (current != null) return current;

    // Try saved location
    final saved = await getSavedLocation();
    if (saved != null) return saved;

    // Return default (Jakarta)
    return UserLocation.defaultLocation();
  }

  /// Map Geolocator permission to our enum
  static LocationPermissionStatus _mapPermission(
      LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      default:
        return LocationPermissionStatus.unknown;
    }
  }
}
