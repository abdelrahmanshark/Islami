/// One page metadata entry from quran_with_juz_hizb_rub.json (all fields 1-based).
class MoshafPageMarker {
  final int page;
  final int sura;
  final int aya;
  final int juz;
  final int hizb;
  final int rub;

  const MoshafPageMarker({
    required this.page,
    required this.sura,
    required this.aya,
    required this.juz,
    required this.hizb,
    required this.rub,
  });

  /// Builds a marker from one JSON object.
  factory MoshafPageMarker.fromJson(Map<String, dynamic> json) {
    return MoshafPageMarker(
      page: json['page'] as int,
      sura: json['sura'] as int,
      aya: json['aya'] as int,
      juz: json['juz'] as int,
      hizb: json['hizb'] as int,
      rub: json['rub'] as int,
    );
  }
}
