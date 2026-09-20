/// One row in the Mushaf index (Surah / Juz / Hizb / Rub).
class MoshafIndexItem {
  final String title;
  final int pageNumber;

  const MoshafIndexItem({
    required this.title,
    required this.pageNumber,
  });
}
