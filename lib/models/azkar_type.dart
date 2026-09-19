/// Which azkar list to show on the Azkar screen.
enum AzkarType {
  morning,
  evening,
}

extension AzkarTypeX on AzkarType {
  /// AppBar / screen title for this azkar type.
  String get title {
    switch (this) {
      case AzkarType.morning:
        return 'أذكار الصباح';
      case AzkarType.evening:
        return 'أذكار المساء';
    }
  }
}
