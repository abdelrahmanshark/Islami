/// One ayah shown inside a Moshaf page.
class MoshafAyah {
  /// 1-based sura number.
  final int sura;

  /// 1-based ayah number.
  final int aya;

  final String text;

  /// True when this ayah is the first ayah of its Surah on this page.
  final bool startsSura;

  const MoshafAyah({
    required this.sura,
    required this.aya,
    required this.text,
    required this.startsSura,
  });
}

/// One of the 604 Mushaf pages built from page markers + Surah text files.
class MoshafPage {
  final int pageNumber;
  final List<MoshafAyah> ayahs;

  const MoshafPage({
    required this.pageNumber,
    required this.ayahs,
  });

  /// Surah used for the AppBar while this page is visible (0-based index).
  int get primarySuraIndex {
    if (ayahs.isEmpty) return 0;
    return ayahs.first.sura - 1;
  }
}
