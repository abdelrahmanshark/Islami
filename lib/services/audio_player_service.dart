import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:islami/utils/network_utils.dart';
import 'package:just_audio/just_audio.dart';

/// Why the last play attempt failed (if any).
enum PlaybackBlockReason {
  call,
  offline,
  failed,
}

/// Shared app audio player. Keep [handleInterruptions] enabled so Quran /
/// lectures pause on phone calls / other apps and resume when focus returns.
///
/// Also notifies listeners when [activeAudioType] changes (drives the mini player).
@lazySingleton
class AudioPlayerService extends ChangeNotifier {
  AudioPlayerService(this._callAudioGuard) {
    _debugListenToPlayerState();
  }

  final CallAudioGuard _callAudioGuard;

  /// just_audio pauses on interruption and resumes when appropriate.
  final AudioPlayer player = AudioPlayer();

  // TEMP AUDIO DEBUG (switching investigation) — remove after.
  final Stopwatch _debugClock = Stopwatch()..start();
  ProcessingState? _debugLastState;
  bool? _debugLastPlaying;

  // TEMP AUDIO DEBUG: prints a timestamped line (visible in logcat as I/flutter).
  void debugAudio(String message) {
    debugPrint('[AUDIO_DEBUG] t=${_debugClock.elapsedMilliseconds}ms '
        'req=$_playRequestId $message');
  }

  // TEMP AUDIO DEBUG: logs every processingState / playing change.
  void _debugListenToPlayerState() {
    player.playerStateStream.listen((state) {
      if (state.processingState == _debugLastState &&
          state.playing == _debugLastPlaying) {
        return;
      }
      _debugLastState = state.processingState;
      _debugLastPlaying = state.playing;
      debugAudio('state -> ${state.processingState.name} '
          'playing=${state.playing}');
    });
  }

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
    if (await _callAudioGuard.isPhoneCallActive()) {
      lastBlockReason = PlaybackBlockReason.call;
      AppMessenger.showSnackBar(CallAudioGuard.callBlockedMessage);
      return false;
    }
    return true;
  }

  /// Returns false and remembers [PlaybackBlockReason.offline] when the
  /// internet check fails.
  Future<bool> ensureOnline() async {
    if (!await NetworkUtils.hasInternetConnection()) {
      lastBlockReason = PlaybackBlockReason.offline;
      return false;
    }
    return true;
  }

  /// Remembers that the player itself failed (not a call / offline block).
  void markPlaybackFailed() {
    lastBlockReason = PlaybackBlockReason.failed;
  }

  // Id of the latest play request; older requests must not touch the player.
  int _playRequestId = 0;

  /// Starts a new play request and returns its id.
  /// Any older request still loading becomes stale.
  int startPlayRequest() {
    _playRequestId++;
    debugAudio('startPlayRequest -> $_playRequestId');
    return _playRequestId;
  }

  /// Makes every in-flight play request stale (call before [AudioPlayer.stop]).
  void cancelPlayRequests() {
    _playRequestId++;
  }

  /// True when a newer play request or a stop replaced [requestId].
  bool isStalePlayRequest(int requestId) {
    final bool isStale = requestId != _playRequestId;
    if (isStale) {
      debugAudio('STALE request $requestId (latest is $_playRequestId)');
    }
    return isStale;
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
    final Stopwatch debugWatch = Stopwatch()..start();
    debugAudio('play() start (playing=${player.playing}, '
        'state=${player.processingState.name})');
    if (!await ensureCanPlay()) {
      debugAudio('play() blocked by call after '
          '${debugWatch.elapsedMilliseconds}ms');
      return false;
    }
    // Fire-and-forget: AudioPlayer.play() completes when the track ends.
    // catchError keeps an interrupted play (e.g. by stop) from being unhandled.
    player.play().catchError((Object error) {
      log(error.toString());
    });
    debugAudio('play() end after ${debugWatch.elapsedMilliseconds}ms '
        '(playing=${player.playing})');
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
  /// Logs the URL before loading so it shows even if the source fails.
  AudioSource buildUriAudioSource(
    Uri uri, {
    dynamic tag,
  }) {
    if (uri.toString().isNotEmpty) {
      log('Playing audio url: $uri');
      debugAudio('source url: $uri');
    }
    return AudioSource.uri(uri, tag: tag);
  }
}
