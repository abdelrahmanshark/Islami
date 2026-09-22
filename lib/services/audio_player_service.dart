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
}
