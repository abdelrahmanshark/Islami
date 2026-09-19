/// One page-start marker from quran.json (page / sura / aya are 1-based).
class MoshafPageMarker {
  final int page;
  final int sura;
  final int aya;

  const MoshafPageMarker({
    required this.page,
    required this.sura,
    required this.aya,
  });

  /// Builds a marker from one JSON object.
  factory MoshafPageMarker.fromJson(Map<String, dynamic> json) {
    return MoshafPageMarker(
      page: json['page'] as int,
      sura: json['sura'] as int,
      aya: json['aya'] as int,
    );
  }
}
