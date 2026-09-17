import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:islami/api_manger/api_manger.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';

class TimeViewModel extends ChangeNotifier {
  TimeViewModel() {
    getTimeResponse();
  }

  static const List<String> _salahNames = [
    'الفجر',
    'الظهر',
    'العصر',
    'المغرب',
    'العشاء',
  ];

  List<Prayer> pryerTimes = [];
  Timings? timing;
  DateInfo? dateInfo;
  bool isTimeLoading = false;
  String timeFailureMsg = '';

  Prayer? nextPrayer;
  int nextPrayerIndex = -1;
  Duration remainingTime = Duration.zero;
  Timer? _countdownTimer;

  String get remainingTimeFormatted {
    final hours = remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> getTimeResponse() async {
    isTimeLoading = true;
    timeFailureMsg = '';
    notifyListeners();
    try {
      var timeResponse = await ApiManger.getTimeResponse();
      timing = timeResponse.data?.timings;
      dateInfo = timeResponse.data?.date;
      pryerTimes = getPryerTimesList(timing);
      isTimeLoading = false;
      _updateNextPrayer();
      _startCountdownTimer();
      notifyListeners();
    } catch (e) {
      log(e.toString());
      isTimeLoading = false;
      timeFailureMsg = 'something went wrong';
      notifyListeners();
    }
  }

  List<Prayer> getPryerTimesList(Timings? timing) {
    return [
      Prayer(_cleanTime(timing?.sunrise), 'الشروق'),
      Prayer(_cleanTime(timing?.fajr), 'الفجر'),
      Prayer(_cleanTime(timing?.dhuhr), 'الظهر'),
      Prayer(_cleanTime(timing?.asr), 'العصر'),
      Prayer(_cleanTime(timing?.maghrib), 'المغرب'),
      Prayer(_cleanTime(timing?.sunset), 'الغروب'),
      Prayer(_cleanTime(timing?.isha), 'العشاء'),
      Prayer(_cleanTime(timing?.midnight), 'منتصف الليل'),
    ];
  }

  String _cleanTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '';
    return rawTime.split(' ').first.trim();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
      notifyListeners();
    });
  }

  void _updateNextPrayer() {
    if (pryerTimes.isEmpty) {
      nextPrayer = null;
      nextPrayerIndex = -1;
      remainingTime = Duration.zero;
      return;
    }

    final now = DateTime.now();
    final salahEntries = <({int index, Prayer prayer, DateTime dateTime})>[];

    for (var i = 0; i < pryerTimes.length; i++) {
      final prayer = pryerTimes[i];
      if (!_salahNames.contains(prayer.PryerName)) continue;
      final dateTime = _toTodayDateTime(prayer.PryerTime, now);
      if (dateTime == null) continue;
      salahEntries.add((index: i, prayer: prayer, dateTime: dateTime));
    }

    if (salahEntries.isEmpty) {
      nextPrayer = null;
      nextPrayerIndex = -1;
      remainingTime = Duration.zero;
      return;
    }

    ({int index, Prayer prayer, DateTime dateTime})? upcoming;
    for (final entry in salahEntries) {
      if (entry.dateTime.isAfter(now)) {
        upcoming = entry;
        break;
      }
    }

    if (upcoming == null) {
      final fajr = salahEntries.first;
      final tomorrowFajr = fajr.dateTime.add(const Duration(days: 1));
      nextPrayer = fajr.prayer;
      nextPrayerIndex = fajr.index;
      remainingTime = tomorrowFajr.difference(now);
      return;
    }

    nextPrayer = upcoming.prayer;
    nextPrayerIndex = upcoming.index;
    remainingTime = upcoming.dateTime.difference(now);
  }

  DateTime? _toTodayDateTime(String time, DateTime now) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
