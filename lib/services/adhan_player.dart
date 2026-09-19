import 'dart:async';
import 'dart:developer';

import 'package:islami/utils/app_assets.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the Adhan audio asset with a dedicated JustAudio player.
class AdhanPlayer {
  AdhanPlayer._();

  /// Plays azan.mp3 and waits until playback finishes.
  static Future<void> play() async {
    final AudioPlayer player = AudioPlayer();
    try {
      await player.setAudioSource(AudioSource.asset(AppAssets.azan));
      await player.play();

      // Wait until the track completes so the alarm isolate stays alive.
      await player.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (e) {
      log('AdhanPlayer error: $e');
    } finally {
      await player.dispose();
    }
  }
}
