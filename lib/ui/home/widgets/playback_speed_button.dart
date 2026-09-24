import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/utils/app_styles.dart';

/// Compact speed button (e.g. "1.5x") used by the audio cards and mini player.
/// The label animates when the speed changes.
class PlaybackSpeedButton extends StatelessWidget {
  const PlaybackSpeedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: AnimatedIconSwitcher(
        child: Text(
          label,
          key: ValueKey(label),
          style: AppStyles.blackBold16,
        ),
      ),
    );
  }
}
