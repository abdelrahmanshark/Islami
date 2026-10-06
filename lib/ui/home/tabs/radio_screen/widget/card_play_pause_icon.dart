import 'package:flutter/material.dart';
import 'package:islami/ui/home/widget/animated_icon_switcher.dart';
import 'package:islami/utils/app_colors.dart';

/// Play button icon for the audio cards: a spinner while the audio is
/// loading, otherwise pause (playing) or play.
class CardPlayPauseIcon extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;

  const CardPlayPauseIcon({
    super.key,
    required this.isLoading,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedIconSwitcher(
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 40,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: AppColors.blackColor,
                  strokeWidth: 3,
                ),
              ),
            )
          : Icon(
              isPlaying ? Icons.pause : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: AppColors.blackColor,
              size: 40,
            ),
    );
  }
}
