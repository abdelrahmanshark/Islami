/// Single azkar entry from the local JSON asset.
class AzkarItem {
  AzkarItem({this.content, this.count});

  AzkarItem.fromJson(dynamic json) {
    content = json['content'];
    count = json['count'];
  }

  String? content;
  String? count;

  /// Parses count as an int (defaults to 1).
  int get countAsInt => int.tryParse(count ?? '1') ?? 1;
}

/// Parsed morning and evening azkar lists.
class AzkarResponse {
  static const String morningKey = 'أذكار الصباح';
  static const String eveningKey = 'أذكار المساء';

  AzkarResponse({this.morningAzkar, this.eveningAzkar});

  /// Builds response from the azkar.json map.
  AzkarResponse.fromJson(Map<String, dynamic> json) {
    morningAzkar = _parseList(json[morningKey]);
    eveningAzkar = _parseList(json[eveningKey]);
  }

  List<AzkarItem>? morningAzkar;
  List<AzkarItem>? eveningAzkar;

  /// Converts a JSON list into AzkarItem objects.
  List<AzkarItem> _parseList(dynamic list) {
    if (list == null) return [];
    return (list as List).map((item) => AzkarItem.fromJson(item)).toList();
  }
}
