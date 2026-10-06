import 'dart:ui';

/// One ayah hit-region from a page JSON in quran_coordinates.
///
/// Coordinates use the Madani page space (345 × 550).
class AyahCoordinate {
  final int surahNumber;
  final int ayahNumber;
  final double x;
  final double y;

  /// One or more polygons for this ayah (multi-line ayahs have several).
  final List<List<Offset>> polygons;

  const AyahCoordinate({
    required this.surahNumber,
    required this.ayahNumber,
    required this.x,
    required this.y,
    required this.polygons,
  });

  /// Builds from one JSON object and parses its polygon string.
  factory AyahCoordinate.fromJson(Map<String, dynamic> json) {
    final polygonRaw = json['polygon'] as String? ?? '';
    return AyahCoordinate(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      polygons: parsePolygonString(polygonRaw),
    );
  }

  /// True when this ayah matches [other] by surah and ayah number.
  bool isSameAyah(AyahCoordinate other) {
    return surahNumber == other.surahNumber && ayahNumber == other.ayahNumber;
  }

  /// Builds a Path in display pixels using [scaleX] and [scaleY].
  Path toScaledPath(double scaleX, double scaleY) {
    final path = Path();
    for (final polygon in polygons) {
      if (polygon.isEmpty) continue;
      path.moveTo(polygon.first.dx * scaleX, polygon.first.dy * scaleY);
      for (var i = 1; i < polygon.length; i++) {
        path.lineTo(polygon[i].dx * scaleX, polygon[i].dy * scaleY);
      }
      path.close();
    }
    return path;
  }

  /// Returns true if [localPosition] is inside any scaled polygon.
  bool contains(Offset localPosition, double scaleX, double scaleY) {
    final path = toScaledPath(scaleX, scaleY);
    return path.contains(localPosition);
  }

  /// Bounding box of all polygons in display pixels.
  Rect scaledBounds(double scaleX, double scaleY) {
    double? minX;
    double? minY;
    double? maxX;
    double? maxY;

    for (final polygon in polygons) {
      for (final point in polygon) {
        final dx = point.dx * scaleX;
        final dy = point.dy * scaleY;
        minX = minX == null ? dx : (dx < minX ? dx : minX);
        minY = minY == null ? dy : (dy < minY ? dy : minY);
        maxX = maxX == null ? dx : (dx > maxX ? dx : maxX);
        maxY = maxY == null ? dy : (dy > maxY ? dy : maxY);
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null) {
      return Rect.zero;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Parses either SVG path (`M … L … Z`) or space-separated `x,y` pairs.
  static List<List<Offset>> parsePolygonString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    if (RegExp(r'[MLZmlz]').hasMatch(trimmed)) {
      return _parseSvgPath(trimmed);
    }
    return [_parsePointList(trimmed)];
  }

  /// Parses `"x,y x,y …"` into one polygon.
  static List<Offset> _parsePointList(String raw) {
    final points = <Offset>[];
    final tokens = raw.split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token.isEmpty) continue;
      final parts = token.split(',');
      if (parts.length < 2) continue;
      final dx = double.tryParse(parts[0]);
      final dy = double.tryParse(parts[1]);
      if (dx == null || dy == null) continue;
      points.add(Offset(dx, dy));
    }
    return points;
  }

  /// Parses simple SVG path commands used in the coordinate JSON (M, L, Z).
  static List<List<Offset>> _parseSvgPath(String raw) {
    final polygons = <List<Offset>>[];
    List<Offset>? current;

    // Split into commands and numbers, e.g. M 0 0 L 10 0 Z
    final tokens = RegExp(
      r'[MLZmlz]|[-+]?(?:\d+\.?\d*|\.\d+)',
    ).allMatches(raw).map((m) => m.group(0)!).toList();

    var i = 0;
    while (i < tokens.length) {
      final token = tokens[i];
      if (token == 'M' || token == 'm') {
        current = <Offset>[];
        polygons.add(current);
        i++;
        if (i + 1 < tokens.length) {
          final dx = double.parse(tokens[i]);
          final dy = double.parse(tokens[i + 1]);
          current.add(Offset(dx, dy));
          i += 2;
        }
      } else if (token == 'L' || token == 'l') {
        i++;
        if (current != null && i + 1 < tokens.length) {
          final dx = double.parse(tokens[i]);
          final dy = double.parse(tokens[i + 1]);
          current.add(Offset(dx, dy));
          i += 2;
        }
      } else if (token == 'Z' || token == 'z') {
        // Close current sub-path; next M starts a new polygon.
        current = null;
        i++;
      } else {
        // Bare number pair without a command — treat as L.
        if (current != null && i + 1 < tokens.length) {
          final dx = double.tryParse(tokens[i]);
          final dy = double.tryParse(tokens[i + 1]);
          if (dx != null && dy != null) {
            current.add(Offset(dx, dy));
            i += 2;
            continue;
          }
        }
        i++;
      }
    }

    return polygons.where((p) => p.isNotEmpty).toList();
  }
}
