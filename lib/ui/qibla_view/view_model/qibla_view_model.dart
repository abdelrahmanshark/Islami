import 'dart:async';
import 'dart:developer';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islami/utils/qibla_calculator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Screen states for the Qibla feature.
enum QiblaUiState {
  loading,
  ready,
  permissionDenied,
  locationDisabled,
  sensorUnavailable,
  error,
}

class QiblaViewModel extends ChangeNotifier {
  QiblaUiState uiState = QiblaUiState.loading;
  String errorMessage = '';

  /// Device heading toward north (degrees).
  double direction = 0;

  /// Qibla angle relative to the device (degrees).
  double qibla = 0;

  /// Angle from north to Qibla (degrees).
  double offset = 0;

  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _compassTimeout;
  bool _isInitializing = false;
  bool _receivedHeading = false;

  QiblaViewModel() {
    initQibla();
  }

  /// True when the phone is roughly facing the Qibla.
  bool get isFacingQibla {
    final angle = qibla % 360;
    final distanceToZero = angle > 180 ? 360 - angle : angle;
    return distanceToZero <= 5;
  }

  /// Qibla offset text shown under the compass.
  String get offsetText => '${offset.toStringAsFixed(1)}°';

  /// Short Arabic guidance for the user.
  String get instructionText {
    if (isFacingQibla) {
      return 'أنت الآن في اتجاه القبلة ✓';
    }
    return 'حرّك هاتفك حتى يتطابق السهم مع علامة القبلة';
  }

  /// Compass rotation in radians (device heading).
  double get compassRadians => direction * (pi / 180) * -1;

  /// Needle rotation in radians (Qibla relative to device).
  double get needleRadians => qibla * (pi / 180) * -1;

  /// Checks location permission, reads GPS, then starts the compass stream.
  Future<void> initQibla() async {
    if (_isInitializing) return;
    _isInitializing = true;

    await _stopCompass();
    uiState = QiblaUiState.loading;
    errorMessage = '';
    notifyListeners();

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        uiState = QiblaUiState.locationDisabled;
        errorMessage = 'يرجى تفعيل خدمة الموقع من إعدادات الجهاز';
        notifyListeners();
        return;
      }

      final LocationPermission permission = await _ensurePermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        uiState = QiblaUiState.permissionDenied;
        errorMessage =
            'يرجى السماح بالوصول إلى الموقع لاستخدام بوصلة القبلة';
        notifyListeners();
        return;
      }

      // One GPS fix is enough to compute the Qibla bearing.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      offset = QiblaCalculator.offsetFromNorth(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _startCompassStream();
    } catch (e, stackTrace) {
      log('Qibla init failed: $e', stackTrace: stackTrace);
      uiState = QiblaUiState.error;
      errorMessage = 'حدث خطأ أثناء تحميل القبلة';
      notifyListeners();
    } finally {
      _isInitializing = false;
    }
  }

  /// Retries after opening system settings when needed.
  Future<void> retry() async {
    if (uiState == QiblaUiState.locationDisabled) {
      await Geolocator.openLocationSettings();
    } else if (uiState == QiblaUiState.permissionDenied) {
      final LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
      }
    }

    await initQibla();
  }

  /// Requests location permission when it is still denied.
  Future<LocationPermission> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Listens to live compass heading and updates Qibla angles.
  Future<void> _startCompassStream() async {
    final Stream<CompassEvent>? compassStream = FlutterCompass.events;
    if (compassStream == null) {
      uiState = QiblaUiState.sensorUnavailable;
      errorMessage = 'مستشعر البوصلة غير متوفر على هذا الجهاز';
      notifyListeners();
      return;
    }

    _receivedHeading = false;
    _compassSubscription = compassStream.listen(
      (CompassEvent event) {
        final double? heading = event.heading;
        // Android may send null while the sensor is calibrating.
        if (heading == null) return;

        _receivedHeading = true;
        _compassTimeout?.cancel();
        direction = heading;
        qibla = QiblaCalculator.relativeQibla(
          heading: heading,
          offset: offset,
        );
        uiState = QiblaUiState.ready;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        log('Qibla compass stream failed: $error', stackTrace: stackTrace);
        _compassTimeout?.cancel();
        uiState = QiblaUiState.error;
        errorMessage = 'حدث خطأ أثناء قراءة اتجاه القبلة';
        notifyListeners();
      },
    );

    // Avoid endless loading when the sensor never emits a heading.
    _compassTimeout = Timer(const Duration(seconds: 5), () {
      if (!_receivedHeading && uiState == QiblaUiState.loading) {
        uiState = QiblaUiState.sensorUnavailable;
        errorMessage =
            'تعذر قراءة البوصلة. حرّك الهاتف بعيدًا عن المعادن ثم أعد المحاولة';
        notifyListeners();
      }
    });
  }

  /// Cancels the compass subscription before a retry or dispose.
  Future<void> _stopCompass() async {
    _compassTimeout?.cancel();
    _compassTimeout = null;
    await _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  @override
  void dispose() {
    _compassTimeout?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }
}
