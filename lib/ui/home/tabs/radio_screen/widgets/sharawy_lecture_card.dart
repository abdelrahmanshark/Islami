import 'package:flutter/material.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_audio_slider.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/ui/home/widgets/playback_speed_button.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Lecture card with play/pause, speed cycle, and seek slider.
class SharawyLectureCard extends StatelessWidget {
  final QuranStoryLecture lecture;

  const SharawyLectureCard({super.key, required this.lecture});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        final isLectureOn =
            provider.selectedSharawyAudioUrl != null &&
            provider.selectedSharawyAudioUrl == lecture.mp3Url;
        final isLecturePlaying = isLectureOn && provider.player.playing;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.fromLTRB(8, 8, 8, isLectureOn ? 6 : 8),
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
                      lecture.title,
                      style: AppStyles.blackBold16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Stop playback when this lecture is active.
                  if (isLectureOn)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: provider.stopSharawyLecture,
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
                      final bool played =
                          await provider.playSharawyLecture(lecture);
                      if (!played && context.mounted) {
                        showPlaybackFailureSnackBar(context);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    icon: AnimatedIconSwitcher(
                      child: Icon(
                        isLecturePlaying
                            ? Icons.pause
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isLecturePlaying),
                        color: AppColors.blackColor,
                        size: 40,
                      ),
                    ),
                  ),
                  if (isLectureOn)
                    PlaybackSpeedButton(
                      label: provider.playbackSpeedLabel,
                      onPressed: provider.cyclePlaybackSpeed,
                    ),
                ],
              ),
              if (isLectureOn) const SharawyAudioSlider(),
            ],
          ),
        );
      },
    );
  }
}
