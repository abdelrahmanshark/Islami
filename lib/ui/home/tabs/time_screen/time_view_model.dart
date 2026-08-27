import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:islami/api_manger/api_manger.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';

class TimeViewModel extends ChangeNotifier {
  TimeViewModel() {
    getTimeResponse();
  }

  List<Prayer> pryerTimes = [];
  Timings? timing;

  DateInfo? dateInfo;
  bool isTimeLoading = false;
  String timeFailureMsg = '';

  Future<void> getTimeResponse() async {
    isTimeLoading = true;
    try {
      var timeResponse = await ApiManger.getTimeResponse();
      timing = timeResponse.data?.timings;
      dateInfo = timeResponse.data?.date;
      isTimeLoading = false;
      pryerTimes = getPryerTimesList(timing);
      notifyListeners();
    } catch (e) {
      log(e.toString());
      isTimeLoading = false;
      timeFailureMsg = 'something went wrong';
      rethrow;
    }
  }

  List<Prayer> getPryerTimesList(Timings? timing) {
    return [
      Prayer(timing?.sunrise ?? '', 'الشروق'),
      Prayer(timing?.fajr ?? '', 'الفجر'),
      Prayer(timing?.dhuhr ?? '', 'الظهر'),
      Prayer(timing?.asr ?? '', 'العصر'),
      Prayer(timing?.maghrib ?? '', 'المغرب'),
      Prayer(timing?.sunset ?? '', 'الغروب'),
      Prayer(timing?.isha ?? '', 'العشاء'),
      Prayer(timing?.midnight ?? '', 'منتصف الليل'),
    ];
  }
}
