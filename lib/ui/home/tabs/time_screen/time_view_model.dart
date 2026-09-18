import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:islami/data/time/time_repository.dart';
import 'package:islami/domain/repositories/time_repository.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class TimeViewModel extends ChangeNotifier {
  TimeViewModel({TimeRepository? timeRepository})
      : _timeRepository = timeRepository ?? TimeRepositoryImpl() {
    _loadAzanEnabled();
    getTimeResponse();
  }

  final TimeRepository _timeRepository;
  final AudioPlayer _player = AudioPlayerService.instance.player;

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
  bool isAzanEnabled = true;

  Prayer? nextPrayer;
  int nextPrayerIndex = -1;
  Duration remainingTime = Duration.zero;
  Timer? _countdownTimer;

  String? _trackedNextPrayerName;
  bool _isCountdownReady = false;
  bool _isAzanPlaying = false;
  StreamSubscription<PlayerState>? _azanPlayerSubscription;

  /// Loads the saved azan on/off preference (defaults to on).
  Future<void> _loadAzanEnabled() async {
    isAzanEnabled = await getAzanEnabled();
    notifyListeners();
  }

  /// Toggles azan sound and stops playback if turning off.
  Future<void> toggleAzanSound() async {
    isAzanEnabled = !isAzanEnabled;
    await saveAzanEnabled(isAzanEnabled);

    if (!isAzanEnabled && _isAzanPlaying) {
      await _player.stop();
      _isAzanPlaying = false;
    }

    notifyListeners();
  }

  String get remainingTimeFormatted {
    String hours = remainingTime.inHours.toString().padLeft(2, '0');
    String minutes =
        (remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    String seconds =
        (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Loads prayer times from the repository and starts the countdown.
  Future<void> getTimeResponse() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownReady = false;
    _trackedNextPrayerName = null;

    isTimeLoading = true;
    timeFailureMsg = '';
    notifyListeners();

    try {
      final timeResponse = await _timeRepository.getTimeResponse();
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

  /// Builds the list of prayers shown in the carousel.
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

  /// Removes timezone suffix and converts the time to 12-hour format.
  String _cleanTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) {
      return '';
    }

    String time = rawTime.split(' ').first.trim();
    List<String> parts = time.split(':');
    if (parts.length < 2) {
      return time;
    }

    int? hour = int.tryParse(parts[0]);
    int? minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return time;
    }

    String period = hour >= 12 ? 'PM' : 'AM';
    int hour12 = hour % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }

    String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  /// Tick every second so the remaining-time banner stays current.
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNextPrayer();
      notifyListeners();
    });
  }

  /// Finds the next salah and updates remaining time.
  void _updateNextPrayer() {
    if (pryerTimes.isEmpty) {
      nextPrayer = null;
      nextPrayerIndex = -1;
      remainingTime = Duration.zero;
      return;
    }

    DateTime now = DateTime.now();

    Prayer? foundPrayer;
    int foundIndex = -1;
    DateTime? foundDateTime;

    // Find the first salah that is still ahead today
    for (int i = 0; i < pryerTimes.length; i++) {
      Prayer prayer = pryerTimes[i];

      if (!_salahNames.contains(prayer.PryerName)) {
        continue;
      }

      DateTime? prayerDateTime = _toTodayDateTime(prayer.PryerTime, now);
      if (prayerDateTime == null) {
        continue;
      }

      if (prayerDateTime.isAfter(now)) {
        foundPrayer = prayer;
        foundIndex = i;
        foundDateTime = prayerDateTime;
        break;
      }
    }

    // If no upcoming salah today, next is Fajr tomorrow
    if (foundPrayer == null) {
      for (int i = 0; i < pryerTimes.length; i++) {
        Prayer prayer = pryerTimes[i];

        if (prayer.PryerName != 'الفجر') {
          continue;
        }

        DateTime? fajrTime = _toTodayDateTime(prayer.PryerTime, now);
        if (fajrTime == null) {
          break;
        }

        foundPrayer = prayer;
        foundIndex = i;
        foundDateTime = fajrTime.add(const Duration(days: 1));
        break;
      }
    }

    if (foundPrayer == null || foundDateTime == null) {
      nextPrayer = null;
      nextPrayerIndex = -1;
      remainingTime = Duration.zero;
      return;
    }

    nextPrayer = foundPrayer;
    nextPrayerIndex = foundIndex;
    remainingTime = foundDateTime.difference(now);

    // Play azan when the next salah changes after the countdown is ready
    final String? currentNextName = nextPrayer?.PryerName;
    if (_isCountdownReady &&
        _trackedNextPrayerName != null &&
        currentNextName != _trackedNextPrayerName) {
      playAzan();
    }
    _trackedNextPrayerName = currentNextName;
    _isCountdownReady = true;
  }

  /// Plays the azan audio asset when a salah time is reached.
  Future<void> playAzan() async {
    if (!isAzanEnabled || _isAzanPlaying) {
      return;
    }

    _isAzanPlaying = true;
    try {
      await _player.setAudioSource(
        AudioSource.asset(
          AppAssets.azan,
          tag: const MediaItem(
            id: 'azan',
            title: 'الأذان',
            artist: 'Islami',
          ),
        ),
      );
      await _player.play();

      await _azanPlayerSubscription?.cancel();
      _azanPlayerSubscription = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isAzanPlaying = false;
        }
      });
    } catch (e) {
      log(e.toString());
      _isAzanPlaying = false;
    }
  }

  /// Parses "h:mm AM/PM" into a DateTime for today.
  DateTime? _toTodayDateTime(String time, DateTime now) {
    List<String> parts = time.split(' ');
    if (parts.isEmpty) {
      return null;
    }

    List<String> timeParts = parts[0].split(':');
    if (timeParts.length < 2) {
      return null;
    }

    int? hour = int.tryParse(timeParts[0]);
    int? minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    // Convert 12-hour time to 24-hour for DateTime
    if (parts.length >= 2) {
      String period = parts[1].toUpperCase();
      if (period == 'AM' && hour == 12) {
        hour = 0;
      } else if (period == 'PM' && hour != 12) {
        hour = hour + 12;
      }
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _azanPlayerSubscription?.cancel();
    _azanPlayerSubscription = null;
    super.dispose();
  }
}
