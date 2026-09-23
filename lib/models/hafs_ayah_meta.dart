/// One ayah entry from hafs-ayah-meta.json (all fields 1-based).
class HafsAyahMeta {
  final int id;
  final int sura;
  final int aya;
  final int page;
  final int juz;
  final int hizb;
  final int rub;

  const HafsAyahMeta({
    required this.id,
    required this.sura,
    required this.aya,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.rub,
  });

  /// Builds one ayah from a JSON object.
  factory HafsAyahMeta.fromJson(Map<String, dynamic> json) {
    return HafsAyahMeta(
      id: json['id'] as int,
      sura: json['sura'] as int,
      aya: json['aya'] as int,
      page: json['page'] as int,
      juz: json['juz'] as int,
      hizb: json['hizb'] as int,
      rub: json['rub'] as int,
    );
  }
}
