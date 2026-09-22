import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer player = AudioPlayer();

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
