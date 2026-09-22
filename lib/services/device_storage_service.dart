import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads available device storage and checks whether a file can fit.
///
/// Uses the Android shared-storage MethodChannel (no MANAGE_EXTERNAL_STORAGE).
class DeviceStorageService {
  DeviceStorageService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.example.islami/quran_storage');

  final MethodChannel _channel;

  /// Extra free space kept free after a download (10 MB).
  static const int defaultSafetyBufferBytes = 10 * 1024 * 1024;

  /// Returns free bytes on shared external storage, or null when unavailable.
  Future<int?> getAvailableBytes() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<dynamic>('getAvailableBytes');
      if (result is int) return result;
      if (result is num) return result.toInt();
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// True when free space covers [requiredBytes] plus a safety buffer.
  Future<bool> hasEnoughSpace(
    int requiredBytes, {
    int safetyBufferBytes = defaultSafetyBufferBytes,
  }) async {
    final int? available = await getAvailableBytes();
    if (available == null) {
      // Unknown capacity — do not block; download layer can decide later.
      return true;
    }

    final int needed = requiredBytes + safetyBufferBytes;
    return available >= needed;
  }
}
