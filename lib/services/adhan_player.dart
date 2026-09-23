import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/services/prayer_time_notification_service.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the Adhan audio asset with a dedicated JustAudio player.
///
/// Adhan must NEVER resume after a phone-call / audio-focus interruption.
class AdhanPlayer {
  AdhanPlayer._();

  static AudioPlayer? _player;
  static StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  static Completer<void>? _finishedCompleter;

  /// Plays azan.mp3, or shows a prayer-time notification if a call is active.
  static Future<void> play({required String prayerName}) async {
    // Skip Adhan entirely while the user is already on a call.
    if (await CallAudioGuard.instance.isPhoneCallActive()) {
      await PrayerTimeNotificationService.showPrayerTime(prayerName);
      return;
    }

    final AudioPlayer player = AudioPlayer(handleInterruptions: false);
    _player = player;
    final Completer<void> finished = Completer<void>();
    _finishedCompleter = finished;

    try {
      await _listenForInterruptions();

      await player.setAudioSource(AudioSource.asset(AppAssets.azan));
      await player.play();

      // Finish when the track completes or when a call stops Adhan.
      await Future.any([
        player.processingStateStream
            .firstWhere((state) => state == ProcessingState.completed),
        finished.future,
      ]);
    } catch (e) {
      log('AdhanPlayer error: $e');
    } finally {
      await _disposePlayer();
    }
  }

  /// Stops Adhan permanently (e.g. incoming/outgoing call). Never resumes.
  static Future<void> stopDueToInterruption() async {
    if (_player == null) {
      return;
    }
    try {
      await _player?.stop();
    } catch (e) {
      log('AdhanPlayer.stopDueToInterruption error: $e');
    }
    final Completer<void>? finished = _finishedCompleter;
    if (finished != null && !finished.isCompleted) {
      finished.complete();
    }
    await _disposePlayer();
  }

  /// Listens for audio-focus loss (calls, other apps, recording, etc.).
  static Future<void> _listenForInterruptions() async {
    await _interruptionSub?.cancel();
    final AudioSession session = await AudioSession.instance;
    _interruptionSub = session.interruptionEventStream.listen((event) async {
      if (!event.begin) {
        return;
      }
      // Any focus-taking interruption ends Adhan for good.
      await stopDueToInterruption();
    });
  }

  /// Releases the dedicated Adhan player and its listeners.
  static Future<void> _disposePlayer() async {
    await _interruptionSub?.cancel();
    _interruptionSub = null;
    _finishedCompleter = null;
    final AudioPlayer? player = _player;
    _player = null;
    if (player != null) {
      try {
        await player.dispose();
      } catch (e) {
        log('AdhanPlayer.dispose error: $e');
      }
    }
  }
}
