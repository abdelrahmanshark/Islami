import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:islami/data/time/time_local_data_source.dart';
import 'package:islami/data/time/time_remote_data_source.dart';
import 'package:islami/domain/repositories/time_repository.dart';
import 'package:islami/models/user_location.dart';
import 'package:islami/services/user_location_service.dart';
import 'package:islami/ui/home/tabs/time_screen/helpers/next_prayer_calculator.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';
import 'package:islami/utils/network_utils.dart';

class TimeRepositoryImpl implements TimeRepository {
  TimeRepositoryImpl({
    TimeRemoteDataSource? remoteDataSource,
    TimeLocalDataSource? localDataSource,
    UserLocationService? locationService,
  })  : _remoteDataSource = remoteDataSource ?? TimeRemoteDataSource(),
        _localDataSource = localDataSource ?? TimeLocalDataSource(),
        _locationService = locationService ?? UserLocationService();

  final TimeRemoteDataSource _remoteDataSource;
  final TimeLocalDataSource _localDataSource;
  final UserLocationService _locationService;

  /// Loads from the API when online and updates the cache.
  /// Falls back to the last cached response when offline.
  @override
  Future<TimeResponse> getTimeResponse() async {
    final bool hasInternet = await NetworkUtils.hasInternetConnection();

    // Offline: serve cache when available; otherwise fail for the UI retry view.
    if (!hasInternet) {
      final TimeResponse? cached = await _localDataSource.loadCachedResponse();
      if (cached != null) {
        return cached;
      }
      throw const SocketException(NetworkUtils.noInternetMessage);
    }

    try {
      final UserLocation location =
          await _locationService.getCurrentLocation();
      final String rawJson = await _remoteDataSource.fetchTimeResponseJson(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      await _localDataSource.saveRawJson(rawJson);
      return TimeResponse.fromJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );
    } catch (e) {
      log('TimeRepository remote failed, trying cache: $e');
      final TimeResponse? cached =
          await _localDataSource.loadCachedResponse();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  /// Minimum cached days before a normal (non-forced) call hits the network.
  static const int _minCachedDays = 3;

  /// Returns prayer times from today for [days] days.
  /// Uses the cache unless [forceRefresh] is true or the cache is too short.
  @override
  Future<List<PrayerData>> getUpcomingPrayerDays({
    required int days,
    bool forceRefresh = false,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<PrayerData> cached = _parseDaysFrom(
      await _localDataSource.loadUpcomingRawJson(),
      today,
    );

    if (!forceRefresh && cached.length >= _minCachedDays) {
      return cached;
    }

    // Only the saved location is used: asking for GPS needs a visible screen.
    final UserLocation? location = await _locationService.getSavedLocation();
    if (location == null || !await NetworkUtils.hasInternetConnection()) {
      return cached;
    }

    try {
      final String rawJson = await _remoteDataSource.fetchCalendarRangeJson(
        latitude: location.latitude,
        longitude: location.longitude,
        from: today,
        to: DateTime(today.year, today.month, today.day + days - 1),
      );
      final List<PrayerData> fresh = _parseDaysFrom(rawJson, today);
      if (fresh.isNotEmpty) {
        await _localDataSource.saveUpcomingRawJson(rawJson);
        return fresh;
      }
    } catch (e) {
      log('TimeRepository upcoming days failed, using cache: $e');
    }
    return cached;
  }

  /// Parses calendar JSON and keeps only the days from [today] onwards.
  List<PrayerData> _parseDaysFrom(String? rawJson, DateTime today) {
    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final Map<String, dynamic> json =
          jsonDecode(rawJson) as Map<String, dynamic>;
      final List<dynamic> items = json['data'] as List<dynamic>? ?? [];

      final List<PrayerData> result = [];
      for (final dynamic item in items) {
        final PrayerData day = PrayerData.fromJson(item as Map<String, dynamic>);
        final DateTime? date =
            NextPrayerCalculator.parseApiDate(day.date?.gregorian?.date);
        if (date != null && !date.isBefore(today)) {
          result.add(day);
        }
      }
      return result;
    } catch (e) {
      log('Invalid cached prayer days: $e');
      return [];
    }
  }
}
