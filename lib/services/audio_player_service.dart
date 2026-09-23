import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:just_audio/just_audio.dart';

/// Why the last gated play attempt was blocked (if any).
enum PlaybackBlockReason {
  call,
}

/// Shared app audio player. Keep [handleInterruptions] enabled so Quran /
/// lectures pause on phone calls / other apps and resume when focus returns.
class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  /// just_audio pauses on interruption and resumes when appropriate.
  final AudioPlayer player = AudioPlayer();

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
