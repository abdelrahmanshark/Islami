/// Removes Arabic tashkeel and normalizes alef variants for search comparison.
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}
