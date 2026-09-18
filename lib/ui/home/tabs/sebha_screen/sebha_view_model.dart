import 'dart:developer';
import 'dart:math' as math;

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

  double angle = 0;
  int counter = 0;
  List<String> azkar = ['سبحان الله', "الحمد لله", " الله اكبر", "أستغفر الله"];
  int azkarIndex = 0;

  List<AzkarItem> morningAzkar = [];
  List<AzkarItem> eveningAzkar = [];
  bool isAzkarLoading = false;
  String azkarFailureMsg = '';

  /// Rotates the sebha and advances the tasbih counter.
  void rotate() {
    angle += math.pi / 33;
    counter++;
    if (counter == 33) {
      counter = 0;
      azkarIndex++;
      if (azkarIndex > 3) {
        azkarIndex = 0;
      }
    }
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
      azkarFailureMsg = 'Failed to load azkar';
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
