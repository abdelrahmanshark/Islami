/// Coordinates and place names used for prayer-time requests and the UI.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.city = '',
    this.country = '',
  });

  final double latitude;
  final double longitude;
  final String city;
  final String country;

  /// True when both city and country are available for display.
  bool get hasPlaceName => city.isNotEmpty && country.isNotEmpty;

  /// Builds "City, Country" text for the location widget.
  String get displayName {
    if (hasPlaceName) {
      return '$city, $country';
    }
    if (city.isNotEmpty) {
      return city;
    }
    if (country.isNotEmpty) {
      return country;
    }
    return '';
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
    );
  }
}
