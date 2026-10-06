import 'package:islami/models/downloaded_audio.dart';

/// Reciter that has at least one downloaded sura.
class DownloadedReciterSummary {
  const DownloadedReciterSummary({
    required this.reciterId,
    required this.reciterName,
    required this.suraCount,
  });

  final int reciterId;
  final String reciterName;
  final int suraCount;
}

/// Groups downloads by reciter for the Downloads tab.
List<DownloadedReciterSummary> buildReciterSummaries(
  List<DownloadedAudio> downloads,
) {
  final Map<int, DownloadedReciterSummary> byId =
      <int, DownloadedReciterSummary>{};

  for (final DownloadedAudio item in downloads) {
    final DownloadedReciterSummary? existing = byId[item.reciterId];
    if (existing == null) {
      byId[item.reciterId] = DownloadedReciterSummary(
        reciterId: item.reciterId,
        reciterName: item.reciterName.isEmpty
            ? 'قارئ ${item.reciterId}'
            : item.reciterName,
        suraCount: 1,
      );
    } else {
      byId[item.reciterId] = DownloadedReciterSummary(
        reciterId: existing.reciterId,
        reciterName: existing.reciterName.isEmpty && item.reciterName.isNotEmpty
            ? item.reciterName
            : existing.reciterName,
        suraCount: existing.suraCount + 1,
      );
    }
  }

  final List<DownloadedReciterSummary> list = byId.values.toList();
  list.sort((a, b) => a.reciterName.compareTo(b.reciterName));
  return list;
}
