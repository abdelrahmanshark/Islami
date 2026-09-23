import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// Detects phone-call / communication audio modes for playback gating.
///
/// Normal Quran/lecture audio pause+resume is handled by [just_audio]'s built-in
/// audio focus interruption handling. This guard is for:
/// - Blocking new playback while a call is active
/// - Letting Adhan decide whether to play or notify
class CallAudioGuard {
  CallAudioGuard._();

  static final CallAudioGuard instance = CallAudioGuard._();

  static const String callBlockedMessage = 'حاول بعد إنهاء المكالمة';

  bool _isInCall = false;
  bool _started = false;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  /// Last known call/ringing state (updated by [isPhoneCallActive]).
  bool get isInCall => _isInCall;

  /// Starts listening so call state stays fresh during the app lifetime.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    try {
      await isPhoneCallActive();

      final AudioSession session = await AudioSession.instance;
      _interruptionSub = session.interruptionEventStream.listen((event) async {
        // Refresh call mode when focus is taken or returned.
        await isPhoneCallActive();
      });
    } catch (e) {
      log('CallAudioGuard.start error: $e');
    }
  }

  /// Stops interruption listening (e.g. tests / dispose).
  Future<void> stop() async {
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    _started = false;
  }

  /// True when the device is ringing or in an active phone/VoIP call.
  Future<bool> isPhoneCallActive() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return _isInCall;
    }

    try {
      final AndroidAudioHardwareMode mode =
          await AndroidAudioManager().getMode();
      _isInCall = mode == AndroidAudioHardwareMode.inCall ||
          mode == AndroidAudioHardwareMode.inCommunication ||
          mode == AndroidAudioHardwareMode.ringtone;
      return _isInCall;
    } catch (e) {
      log('CallAudioGuard.isPhoneCallActive error: $e');
      return _isInCall;
    }
  }
}
