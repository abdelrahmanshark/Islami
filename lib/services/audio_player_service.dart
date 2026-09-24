import 'package:flutter/foundation.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:just_audio/just_audio.dart';

/// Why the last gated play attempt was blocked (if any).
enum PlaybackBlockReason {
  call,
}

/// Shared app audio player. Keep [handleInterruptions] enabled so Quran /
/// lectures pause on phone calls / other apps and resume when focus returns.
///
/// Also notifies listeners when [activeAudioType] changes (drives the mini player).
class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  /// just_audio pauses on interruption and resumes when appropriate.
  final AudioPlayer player = AudioPlayer();

  /// Which audio is selected in [player]; null means nothing is active.
  ActiveAudioType? activeAudioType;

  /// Last non-null [activeAudioType]. Keeps the right mini player mounted
  /// so it can animate out after the audio stops.
  ActiveAudioType? lastActiveAudioType;

  /// Updates [activeAudioType] and notifies listeners only when it changes.
  void setActiveAudioType(ActiveAudioType? type) {
    if (activeAudioType == type) return;
    activeAudioType = type;
    if (type != null) {
      lastActiveAudioType = type;
    }
    notifyListeners();
  }

  /// Set when [ensureCanPlay] blocks because of an active call.
  PlaybackBlockReason? lastBlockReason;

  // Survives RadioViewModel dispose when leaving the Radio tab.
  int? selectedRadioId;
  int? selectedRadioForSoundId;
  int? selectedReciterId;
  String? selectedSermonAudioUrl;
  String? selectedSharawyAudioUrl;
  double playbackSpeed = 1.0;
  int currentSura = 1;
  bool isRepeatEnabled = false;
  bool isAutoNextEnabled = false;

  static const List<double> _playbackSpeeds = [1.0, 1.25, 1.5, 2.0];

  /// Cycles playback speed: 1x → 1.25x → 1.5x → 2x → 1x, and applies it.
  Future<void> cyclePlaybackSpeed() async {
    final int currentIndex = _playbackSpeeds.indexOf(playbackSpeed);
    final int nextIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % _playbackSpeeds.length;
    playbackSpeed = _playbackSpeeds[nextIndex];
    await applyPlaybackSpeed();
  }

  /// Applies the chosen [playbackSpeed] to the player.
  Future<void> applyPlaybackSpeed() async {
    await player.setSpeed(playbackSpeed);
  }

  /// Label for the speed buttons, e.g. "1x" or "1.25x".
  String get playbackSpeedLabel {
    if (playbackSpeed == playbackSpeed.roundToDouble()) {
      return '${playbackSpeed.toInt()}x';
    }
    return '${playbackSpeed}x';
  }

  /// Returns false and shows a snackbar when a phone call is active.
  Future<bool> ensureCanPlay() async {
    lastBlockReason = null;
    if (await CallAudioGuard.instance.isPhoneCallActive()) {
      lastBlockReason = PlaybackBlockReason.call;
      AppMessenger.showSnackBar(CallAudioGuard.callBlockedMessage);
      return false;
    }
    return true;
  }

  /// Reads and clears [lastBlockReason] for UI failure handling.
  PlaybackBlockReason? consumeBlockReason() {
    final PlaybackBlockReason? reason = lastBlockReason;
    lastBlockReason = null;
    return reason;
  }

  /// Starts playback only when no phone call is active.
  ///
  /// Does not await [AudioPlayer.play] — it completes when the track ends.
  Future<bool> play() async {
    if (!await ensureCanPlay()) {
      return false;
    }
    // Fire-and-forget: AudioPlayer.play() completes when the track ends.
    player.play();
    return true;
  }

  /// Prefers a local MediaStore URI when available; otherwise the remote URL.
  /// Keeps current online-only callers unchanged until downloads are wired.
  Uri resolvePlaybackUri({
    required String remoteUrl,
    String? localUri,
  }) {
    if (localUri != null && localUri.isNotEmpty) {
      return Uri.parse(localUri);
    }
    return Uri.parse(remoteUrl);
  }

  /// Builds a just_audio source from a local file URI or an online URL.
  AudioSource buildUriAudioSource(
    Uri uri, {
    dynamic tag,
  }) {
    return AudioSource.uri(uri, tag: tag);
  }
}
