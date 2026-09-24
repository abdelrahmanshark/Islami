import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/mini_player_icon_button.dart';
import 'package:islami/ui/home/widgets/playback_speed_button.dart';

/// Sermon / Sha'rawy lecture controls, same as their cards:
/// stop, play/pause, and playback speed.
class MiniLectureControls extends StatelessWidget {
  const MiniLectureControls({
    super.key,
    required this.isPlaying,
    required this.speedLabel,
    required this.onStop,
    required this.onPlayPause,
    required this.onChangeSpeed,
  });

  final bool isPlaying;
  final String speedLabel;
  final VoidCallback onStop;
  final VoidCallback onPlayPause;
  final VoidCallback onChangeSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MiniPlayerIconButton(icon: Icons.stop_rounded, onPressed: onStop),
        MiniPlayerIconButton(
          icon: isPlaying ? Icons.pause : Icons.play_arrow_rounded,
          size: 34,
          onPressed: onPlayPause,
        ),
        PlaybackSpeedButton(label: speedLabel, onPressed: onChangeSpeed),
      ],
    );
  }
}
