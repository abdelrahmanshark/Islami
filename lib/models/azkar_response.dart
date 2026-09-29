/// Single zikr or duaa inside a category.
class AzkarItem {
  AzkarItem({required this.text, required this.count});

  AzkarItem.fromJson(dynamic json)
      : text = json['text'] ?? '',
        count = json['count'] ?? 1;

  final String text;

  /// How many times this zikr should be repeated.
  final int count;
}

/// A category of azkar/duaa (e.g. "أذكار الصباح") with its items.
class AzkarCategory {
  AzkarCategory({required this.title, required this.items});

  AzkarCategory.fromJson(dynamic json)
      : title = json['category'] ?? '',
        items = (json['items'] as List? ?? [])
            .map((item) => AzkarItem.fromJson(item))
            .toList();

  /// Category name, also used as its unique id for favorites.
  final String title;
  final List<AzkarItem> items;
}

/// All azkar categories parsed from azkar_and_duaa.json.
class AzkarResponse {
  AzkarResponse({required this.categories});

  /// Builds the response from the JSON list of categories.
  AzkarResponse.fromJson(List<dynamic> json)
      : categories =
            json.map((category) => AzkarCategory.fromJson(category)).toList();

  final List<AzkarCategory> categories;
}
