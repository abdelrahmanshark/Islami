import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:islami/data/time/time_repository.dart';
import 'package:islami/domain/repositories/time_repository.dart';
import 'package:islami/services/adhan_alarm_scheduler.dart';
import 'package:islami/services/prayer_widget_updater.dart';
import 'package:islami/ui/home/tabs/time_screen/helpers/next_prayer_calculator.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';
import 'package:islami/utils/shared_preferences.dart';

class TimeViewModel extends ChangeNotifier {
  TimeViewModel({TimeRepository? timeRepository})
      : _timeRepository = timeRepository ?? TimeRepositoryImpl() {
    _loadAzanEnabled();
    getTimeResponse();
  }

  final TimeRepository _timeRepository;

  List<Prayer> pryerTimes = [];
  Timings? timing;
  DateInfo? dateInfo;
  bool isTimeLoading = false;
  String timeFailureMsg = '';
  bool isAzanEnabled = true;

  Prayer? nextPrayer;
  int nextPrayerIndex = -1;
  Duration remainingTime = Duration.zero;
  Timer? _countdownTimer;

  /// Loads the saved azan on/off preference (defaults to on).
  Future<void> _loadAzanEnabled() async {
    isAzanEnabled = await getAzanEnabled();
    notifyListeners();
  }

  /// Toggles azan sound and cancels or reschedules prayer alarms.
  Future<void> toggleAzanSound() async {
    isAzanEnabled = !isAzanEnabled;
    await saveAzanEnabled(isAzanEnabled);

    if (!isAzanEnabled) {
      await AdhanAlarmScheduler.cancelAll();
    } else if (timing != null) {
      await AdhanAlarmScheduler.scheduleFromTimings(timing!);
    } else {
      await AdhanAlarmScheduler.rescheduleFromSaved();
    }

    notifyListeners();
  }

  String get remainingTimeFormatted {
    return NextPrayerCalculator.formatRemainingHms(remainingTime);
  }

  /// Loads prayer times from the repository and starts the countdown.
  Future<void> getTimeResponse() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    isTimeLoading = true;
    timeFailureMsg = '';
    notifyListeners();

    try {
      final timeResponse = await _timeRepository.getTimeResponse();
      timing = timeResponse.data?.timings;
      dateInfo = timeResponse.data?.date;
      pryerTimes = getPryerTimesList(timing);
      isTimeLoading = false;
      _updateNextPrayer(pushWidget: true);
      _startCountdownTimer();

      // Schedule background Adhan alarms from fetched prayer times.
      if (timing != null) {
        await AdhanAlarmScheduler.scheduleFromTimings(timing!);
      }

      notifyListeners();
    } catch (e) {
      log(e.toString());
      isTimeLoading = false;
      timeFailureMsg = 'حدث خطأ ما';
      notifyListeners();
    }
  }

  /// Builds the list of prayers shown in the carousel.
  List<Prayer> getPryerTimesList(Timings? timing) {
    return [
      Prayer(NextPrayerCalculator.cleanTime(timing?.sunrise), 'الشروق'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.fajr), 'الفجر'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.dhuhr), 'الظهر'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.asr), 'العصر'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.maghrib), 'المغرب'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.sunset), 'الغروب'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.isha), 'العشاء'),
      Prayer(NextPrayerCalculator.cleanTime(timing?.midnight), 'منتصف الليل'),
    ];
  }

  /// Tick every second so the in-app remaining-time banner stays current.
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNextPrayer();
      notifyListeners();
    });
  }

  /// Finds the next salah and updates remaining time for the Time screen UI.
  /// Home widget countdown is driven by the stored next-prayer DateTime on Android.
  void _updateNextPrayer({bool pushWidget = false}) {
    final DateTime now = DateTime.now();
    final int previousIndex = nextPrayerIndex;
    final NextPrayerResult? result =
        NextPrayerCalculator.findNext(pryerTimes, now);

    if (result == null) {
      nextPrayer = null;
      nextPrayerIndex = -1;
      remainingTime = Duration.zero;
      if (pushWidget) {
        PrayerWidgetUpdater.update(
          prayerTimes: pryerTimes,
          nextResult: null,
        );
      }
      return;
    }

    nextPrayer = result.prayer;
    nextPrayerIndex = result.index;
    remainingTime = result.remainingFrom(now);

    // Push widget data after fetch, or when the next prayer itself changes.
    if (pushWidget || previousIndex != result.index) {
      PrayerWidgetUpdater.update(
        prayerTimes: pryerTimes,
        nextResult: result,
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    super.dispose();
  }
}
