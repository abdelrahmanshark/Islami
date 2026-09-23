/// One sura entry from assets/json/mshary.json.
class MsharySura {
  MsharySura({
    required this.number,
    required this.name,
    required this.mp3,
    required this.category,
  });

  factory MsharySura.fromJson(Map<String, dynamic> json) {
    return MsharySura(
      number: json['number'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mp3: json['mp3'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  final String number;
  final String name;
  final String mp3;
  final String category;
}
