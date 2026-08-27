import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/hadith.dart';

class HadithModelView extends ChangeNotifier {
  HadithModelView() {}
  Hadith hadith = Hadith(title: '', content: '');

  void loadHadithContent(int index) async {
    String fileContent = await rootBundle.loadString(
      'assets/hadith/h$index.txt',
    );
    hadith.title = fileContent.substring(0, fileContent.indexOf("\n"));
    hadith.content = fileContent.substring(fileContent.indexOf("\n") + 1);
    notifyListeners();
  }
}
