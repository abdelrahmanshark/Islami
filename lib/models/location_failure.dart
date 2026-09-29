/// Why the device location could not be obtained.
enum LocationFailureReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

/// Thrown when there is no saved location and GPS could not provide one.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.reason);

  final LocationFailureReason reason;

  @override
  String toString() => 'LocationUnavailableException: $reason';
}
