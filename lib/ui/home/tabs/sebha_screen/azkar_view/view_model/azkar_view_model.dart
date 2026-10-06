import 'package:flutter/material.dart';
import 'package:islami/models/azkar_response.dart';

class AzkarViewModel extends ChangeNotifier {
  AzkarViewModel({required this.category})
      : remainingCounts = category.items.map((item) => item.count).toList();

  final AzkarCategory category;

  /// Remaining taps left for each azkar item.
  final List<int> remainingCounts;

  /// Decrements the remaining count for the tapped azkar item.
  void onAzkarTapped(int index) {
    if (index < 0 || index >= remainingCounts.length) return;
    if (remainingCounts[index] <= 0) return;

    remainingCounts[index]--;
    notifyListeners();
  }
}
