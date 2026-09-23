import 'package:flutter/material.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermon_audio_slider.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class SermonCard extends StatelessWidget {
  final Sermon sermon;

  const SermonCard({super.key, required this.sermon});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        final isSermonOn =
            provider.selectedSermonAudioUrl != null &&
            provider.selectedSermonAudioUrl == sermon.audioUrl;
        final isSermonPlaying = isSermonOn && provider.player.playing;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.fromLTRB(8, 8, 8, isSermonOn ? 6 : 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      sermon.titleAr,
                      style: AppStyles.blackBold16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Stop playback when this sermon is active.
                  if (isSermonOn)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: provider.stopSermon,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(
                          Icons.stop_rounded,
                          color: AppColors.blackColor,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      final bool played = await provider.playSermon(sermon);
                      if (!played && context.mounted) {
                        showPlaybackFailureSnackBar(context);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isSermonPlaying
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      color: AppColors.blackColor,
                      size: 40,
                    ),
                  ),
                  if (isSermonOn)
                    TextButton(
                      onPressed: provider.cyclePlaybackSpeed,
                      child: Text(
                        provider.playbackSpeedLabel,
                        style: AppStyles.blackBold16,
                      ),
                    ),
                ],
              ),
              if (isSermonOn) const SermonAudioSlider(),
            ],
          ),
        );
      },
    );
  }
}
