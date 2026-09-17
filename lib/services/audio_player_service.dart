import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer player = AudioPlayer();
}