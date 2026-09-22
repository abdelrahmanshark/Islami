import 'dart:developer';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islami/models/user_location.dart';
import 'package:islami/utils/shared_preferences.dart';

/// Resolves the user's coordinates and place names from device GPS.
class UserLocationService {
  /// Cairo, Egypt — used only when location cannot be obtained.
  static const UserLocation _fallbackLocation = UserLocation(
    latitude: 30.0444,
    longitude: 31.2357,
    city: 'القاهرة',
    country: 'مصر',
  );

  final Geocoding _geocoding = Geocoding();

  /// Returns the last saved location, or null when nothing was stored yet.
  Future<UserLocation?> getSavedLocation() async {
    return getSavedUserLocation();
  }

  /// Returns a saved location when available, otherwise GPS or Cairo fallback.
  Future<UserLocation> getCurrentLocation() async {
    final UserLocation? saved = await getSavedLocation();
    if (saved != null) {
      return saved;
    }

    return refreshAndSaveLocation();
  }

  /// Gets accurate GPS, resolves city/country, saves locally, and returns it.
  Future<UserLocation> refreshAndSaveLocation() async {
    try {
      final bool hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        log('Location permission not granted, using fallback');
        await saveUserLocation(_fallbackLocation);
        return _fallbackLocation;
      }

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services are disabled, using fallback');
        await saveUserLocation(_fallbackLocation);
        return _fallbackLocation;
      }

      // High accuracy so prayer times match the user's real position.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final UserLocation location = await _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await saveUserLocation(location);
      return location;
    } catch (e) {
      log('Failed to resolve user location: $e');
      await saveUserLocation(_fallbackLocation);
      return _fallbackLocation;
    }
  }

  /// Converts coordinates into city and country using reverse geocoding.
  Future<UserLocation> _resolvePlaceName({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final List<Placemark> placemarks =
          await _geocoding.placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return UserLocation(latitude: latitude, longitude: longitude);
      }

      final Placemark place = placemarks.first;
      final String city = _pickCity(place);
      final String country = place.country?.trim() ?? '';

      return UserLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
      );
    } catch (e) {
      log('Failed to reverse geocode location: $e');
      return UserLocation(latitude: latitude, longitude: longitude);
    }
  }

  /// Picks the best available city-like field from a placemark.
  String _pickCity(Placemark place) {
    final List<String?> candidates = [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ];

    for (final String? value in candidates) {
      final String trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }

  /// Requests location permission so the OS dialog is shown when needed.
  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // Always request when denied so the permission dialog appears.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      log('Location permission denied: $permission');
      return false;
    }

    return true;
  }
}
