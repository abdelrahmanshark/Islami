import 'dart:developer';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islami/models/location_failure.dart';
import 'package:islami/models/user_location.dart';
import 'package:islami/utils/shared_preferences.dart';

/// Resolves the user's coordinates and place names from device GPS.
class UserLocationService {
  final Geocoding _geocoding = Geocoding();

  /// Returns the last saved location, or null when nothing was stored yet.
  Future<UserLocation?> getSavedLocation() async {
    return getSavedUserLocation();
  }

  /// Returns the saved location when available, otherwise asks GPS for one.
  /// Throws [LocationUnavailableException] when GPS cannot provide it.
  Future<UserLocation> getCurrentLocation() async {
    final UserLocation? saved = await getSavedLocation();
    if (saved != null) {
      return ensureCountryCode(saved);
    }

    return refreshAndSaveLocation();
  }

  /// Fills the country code for locations saved before it was stored.
  /// Uses reverse geocoding only, so no GPS permission is needed.
  Future<UserLocation> ensureCountryCode(UserLocation location) async {
    if (location.countryCode.isNotEmpty) {
      return location;
    }

    final UserLocation resolved = await _resolvePlaceName(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (resolved.countryCode.isEmpty) {
      return location;
    }

    final UserLocation updated = location.copyWith(
      countryCode: resolved.countryCode,
    );
    await saveUserLocation(updated);
    return updated;
  }

  /// Gets accurate GPS, resolves city/country, saves locally, and returns it.
  /// Throws [LocationUnavailableException] instead of using a default city.
  Future<UserLocation> refreshAndSaveLocation() async {
    final LocationFailureReason? permissionFailure =
        await _ensureLocationPermission();
    if (permissionFailure != null) {
      throw LocationUnavailableException(permissionFailure);
    }

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('Location services are disabled');
      throw const LocationUnavailableException(
        LocationFailureReason.serviceDisabled,
      );
    }

    final Position position;
    try {
      // High accuracy so prayer times match the user's real position.
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      log('Failed to get GPS position: $e');
      throw const LocationUnavailableException(
        LocationFailureReason.unavailable,
      );
    }

    final UserLocation location = await _resolvePlaceName(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await saveUserLocation(location);
    return location;
  }

  /// Converts coordinates into city, country and country code.
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
      final String countryCode = place.isoCountryCode?.trim() ?? '';

      return UserLocation(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        countryCode: countryCode,
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
  /// Returns null when granted, otherwise the reason it was refused.
  Future<LocationFailureReason?> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // Always request when denied so the permission dialog appears.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      log('Location permission denied forever');
      return LocationFailureReason.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied) {
      log('Location permission denied');
      return LocationFailureReason.permissionDenied;
    }

    return null;
  }
}
