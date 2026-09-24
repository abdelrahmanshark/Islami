import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/mini_player_icon_button.dart';

/// Radio station controls, same as the radio card: pause and mute.
class MiniRadioControls extends StatelessWidget {
  const MiniRadioControls({
    super.key,
    required this.isSoundOn,
    required this.onPause,
    required this.onToggleSound,
  });

  final bool isSoundOn;
  final VoidCallback onPause;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MiniPlayerIconButton(icon: Icons.pause, size: 34, onPressed: onPause),
        MiniPlayerIconButton(
          icon: isSoundOn ? Icons.volume_up : Icons.volume_off,
          onPressed: onToggleSound,
        ),
      ],
    );
  }
}
