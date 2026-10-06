import 'dart:math' show atan2, cos, sin, pi;

/// Calculates Qibla angles from the user's coordinates and compass heading.
class QiblaCalculator {
  QiblaCalculator._();

  /// Kaaba coordinates in Mecca.
  static const double _kaabaLatitude = 21.422487;
  static const double _kaabaLongitude = 39.826206;

  /// Returns the bearing from north to the Qibla (0–360 degrees).
  static double offsetFromNorth({
    required double latitude,
    required double longitude,
  }) {
    final double lat1 = _toRadians(latitude);
    final double lat2 = _toRadians(_kaabaLatitude);
    final double dLng = _toRadians(_kaabaLongitude - longitude);

    final double y = sin(dLng) * cos(lat2);
    final double x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    final double bearing = atan2(y, x) * 180 / pi;
    return _normalizeDegrees(bearing);
  }

  /// Returns the Qibla angle relative to the device heading (0–360 degrees).
  static double relativeQibla({
    required double heading,
    required double offset,
  }) {
    return _normalizeDegrees(heading - offset);
  }

  /// Converts degrees to radians.
  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Keeps an angle inside the 0–360 range.
  static double _normalizeDegrees(double degrees) {
    final double value = degrees % 360;
    return value < 0 ? value + 360 : value;
  }
}
