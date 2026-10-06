/// What the Riyad Assalihin search field searches in.
enum RiyadSearchType {
  chapter,
  hadith,
}

extension RiyadSearchTypeX on RiyadSearchType {
  /// Label shown in the search type menu.
  String get label {
    switch (this) {
      case RiyadSearchType.chapter:
        return 'الباب';
      case RiyadSearchType.hadith:
        return 'الحديث';
    }
  }

  /// Hint shown inside the search field.
  String get hintText {
    switch (this) {
      case RiyadSearchType.chapter:
        return 'بحث عن باب';
      case RiyadSearchType.hadith:
        return 'بحث في الأحاديث';
    }
  }
}
