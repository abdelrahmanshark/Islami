import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/mini_player_icon_button.dart';

/// Radio station controls, same as the radio card: stop, play/pause, and mute.
class MiniRadioControls extends StatelessWidget {
  const MiniRadioControls({
    super.key,
    required this.isPlaying,
    required this.isSoundOn,
    required this.onStop,
    required this.onPlayPause,
    required this.onToggleSound,
  });

  final bool isPlaying;
  final bool isSoundOn;
  final VoidCallback onStop;
  final VoidCallback onPlayPause;
  final VoidCallback onToggleSound;

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
        MiniPlayerIconButton(
          icon: isSoundOn ? Icons.volume_up : Icons.volume_off,
          onPressed: onToggleSound,
        ),
      ],
    );
  }
}
