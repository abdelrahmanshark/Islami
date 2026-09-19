import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/azkar/azkar_repository.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/models/azkar_type.dart';

class AzkarViewModel extends ChangeNotifier {
  AzkarViewModel({
    required this.azkarType,
    AzkarRepository? azkarRepository,
  }) : _azkarRepository = azkarRepository ?? AzkarRepositoryImpl() {
    loadAzkar();
  }

  final AzkarType azkarType;
  final AzkarRepository _azkarRepository;

  List<AzkarItem> azkarList = [];
  /// Remaining taps left for each azkar item.
  List<int> remainingCounts = [];
  bool isLoading = false;
  String failureMsg = '';

  /// Loads the morning or evening azkar list.
  Future<void> loadAzkar() async {
    try {
      isLoading = true;
      failureMsg = '';
      notifyListeners();

      final response = await _azkarRepository.getAzkar();
      azkarList = azkarType == AzkarType.morning
          ? (response.morningAzkar ?? [])
          : (response.eveningAzkar ?? []);
      remainingCounts = azkarList.map((item) => item.countAsInt).toList();
    } catch (e) {
      log(e.toString());
      failureMsg = 'فشل تحميل الأذكار';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Decrements the remaining count for the tapped azkar item.
  void onAzkarTapped(int index) {
    if (index < 0 || index >= remainingCounts.length) return;
    if (remainingCounts[index] <= 0) return;

    remainingCounts[index]--;
    notifyListeners();
  }
}
