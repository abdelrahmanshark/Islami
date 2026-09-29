/// Removes Arabic tashkeel and tatweel (ـ) and normalizes alef variants
/// for search comparison.
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}
