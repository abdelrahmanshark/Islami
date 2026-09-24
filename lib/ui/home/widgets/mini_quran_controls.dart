import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_mode_icon_button.dart';
import 'package:islami/ui/home/widgets/mini_player_icon_button.dart';
import 'package:islami/ui/home/widgets/playback_speed_button.dart';

/// Reciter / downloaded sura controls, same as the reciter card:
/// stop, repeat, previous, play/pause, next, auto-next, and playback speed.
class MiniQuranControls extends StatelessWidget {
  const MiniQuranControls({
    super.key,
    required this.isPlaying,
    required this.isRepeatEnabled,
    required this.isAutoNextEnabled,
    required this.speedLabel,
    required this.onStop,
    required this.onToggleRepeat,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onToggleAutoNext,
    required this.onChangeSpeed,
  });

  final bool isPlaying;
  final bool isRepeatEnabled;
  final bool isAutoNextEnabled;
  final String speedLabel;
  final VoidCallback onStop;
  final VoidCallback onToggleRepeat;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onToggleAutoNext;
  final VoidCallback onChangeSpeed;

  @override
  Widget build(BuildContext context) {
    // Shrinks the buttons on narrow screens instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MiniPlayerIconButton(icon: Icons.stop_rounded, onPressed: onStop),
          ReciterModeIconButton(
            icon: Icons.repeat_one_rounded,
            isActive: isRepeatEnabled,
            onPressed: onToggleRepeat,
          ),
          MiniPlayerIconButton(
            icon: Icons.skip_previous_rounded,
            onPressed: onPrevious,
          ),
          MiniPlayerIconButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow_rounded,
            size: 34,
            onPressed: onPlayPause,
          ),
          MiniPlayerIconButton(
            icon: Icons.skip_next_rounded,
            onPressed: onNext,
          ),
          ReciterModeIconButton(
            icon: Icons.playlist_play_rounded,
            isActive: isAutoNextEnabled,
            onPressed: onToggleAutoNext,
          ),
          PlaybackSpeedButton(label: speedLabel, onPressed: onChangeSpeed),
        ],
      ),
    );
  }
}
