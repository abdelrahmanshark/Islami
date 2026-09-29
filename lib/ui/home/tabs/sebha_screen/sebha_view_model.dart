import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:islami/data/azkar/azkar_repository.dart';
import 'package:islami/domain/repositories/azkar_repository.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/models/azkar_type.dart';
import 'package:islami/utils/app_routes.dart';

class SebhaViewModel extends ChangeNotifier {
  SebhaViewModel({AzkarRepository? azkarRepository})
      : _azkarRepository = azkarRepository ?? AzkarRepositoryImpl() {
    loadAzkar();
  }

  final AzkarRepository _azkarRepository;

  /// How many tasbihat make one round of the same zikr.
  static const int tasbihLimit = 33;

  /// Sebha rotation in full turns (1.0 = 360°).
  double turns = 0;
  int counter = 0;
  int totalCount = 0;
  List<String> azkar = ['سبحان الله', 'الحمد لله', 'الله أكبر', 'أستغفر الله'];
  int azkarIndex = 0;

  List<AzkarItem> morningAzkar = [];
  List<AzkarItem> eveningAzkar = [];
  bool isAzkarLoading = false;
  String azkarFailureMsg = '';

  /// True when the current zikr reached its last tasbiha (33 of 33).
  bool get isRoundCompleted => counter == tasbihLimit;

  /// Rotates the sebha one bead and advances the tasbih counter.
  /// After 33 the next tap moves to the next zikr and starts again from 1.
  void rotate() {
    turns += 1 / tasbihLimit;
    if (isRoundCompleted) {
      counter = 0;
      azkarIndex = (azkarIndex + 1) % azkar.length;
    }
    counter++;
    totalCount++;
    notifyListeners();
  }

  /// Loads morning/evening azkar from the repository.
  Future<void> loadAzkar() async {
    try {
      isAzkarLoading = true;
      azkarFailureMsg = '';
      notifyListeners();

      final response = await _azkarRepository.getAzkar();
      morningAzkar = response.morningAzkar ?? [];
      eveningAzkar = response.eveningAzkar ?? [];
    } catch (e) {
      log(e.toString());
      azkarFailureMsg = 'فشل تحميل الأذكار';
    } finally {
      isAzkarLoading = false;
      notifyListeners();
    }
  }

  /// Opens the Azkar screen for the selected type.
  void openAzkar(BuildContext context, AzkarType type) {
    Navigator.pushNamed(
      context,
      AppRoutes.azkarRouteName,
      arguments: type,
    );
  }
}
