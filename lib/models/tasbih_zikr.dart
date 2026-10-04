/// One sebha zikr (e.g. "سبحان الله") with its saved counters.
class TasbihZikr {
  TasbihZikr({required this.title, this.roundCount = 0, this.totalCount = 0});

  final String title;

  /// Tasbihat done in the current round (0 up to the round limit).
  int roundCount;

  /// All tasbihat ever done for this zikr.
  int totalCount;
}
