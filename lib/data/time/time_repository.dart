import 'dart:convert';
import 'dart:developer';

import 'package:islami/data/time/time_local_data_source.dart';
import 'package:islami/data/time/time_remote_data_source.dart';
import 'package:islami/domain/repositories/time_repository.dart';
import 'package:islami/models/user_location.dart';
import 'package:islami/services/user_location_service.dart';
import 'package:islami/ui/home/tabs/time_screen/models/TimeResponse.dart';

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
}
