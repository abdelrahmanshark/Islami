import 'dart:math' as math;

import 'package:flutter/material.dart';

class SebhaViewModel extends ChangeNotifier {
  double angle = 0;

  int counter = 0;
  List<String> azkar = ['سبحان الله', "الحمد لله", " الله اكبر", "أستغفر الله"];
  int azkarIndex = 0;

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
}
