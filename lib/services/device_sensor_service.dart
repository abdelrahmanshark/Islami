import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Checks whether the device has the hardware sensors a feature needs.
@lazySingleton
class DeviceSensorService {
  final MethodChannel _channel =
      const MethodChannel('com.example.islami/device_sensors');

  /// Returns true when the device has a magnetic field sensor (magnetometer).
  /// Only Android is checked natively; other platforms are assumed to have it.
  Future<bool> hasMagnetometer() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    try {
      final bool? hasSensor =
          await _channel.invokeMethod<bool>('hasMagnetometer');
      return hasSensor ?? true;
    } on PlatformException catch (e) {
      log('Magnetometer check failed: $e');
      return true;
    } on MissingPluginException catch (e) {
      log('Magnetometer check not available: $e');
      return true;
    }
  }
}
