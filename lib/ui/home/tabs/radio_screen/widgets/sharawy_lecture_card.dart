import 'package:flutter/material.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_audio_slider.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/utils/app_assets.dart';
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
          margin: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
          height: MediaQuery.heightOf(context) * (isLectureOn ? 0.24 : 0.14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: AlignmentGeometry.bottomCenter,
            children: [
              isLectureOn
                  ? Image.asset(AppAssets.activeRadioCard, fit: BoxFit.cover)
                  : Image.asset(AppAssets.inActiveRadioCard),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      lecture.title,
                      style: AppStyles.blackBold18,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
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
                        icon: Icon(
                          isLecturePlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      if (isLectureOn)
                        TextButton(
                          onPressed: () {
                            provider.cyclePlaybackSpeed();
                          },
                          child: Text(
                            provider.playbackSpeedLabel,
                            style: AppStyles.blackBold16,
                          ),
                        ),
                    ],
                  ),
                  if (isLectureOn) const SharawyAudioSlider(),
                ],
              ),
              // Stop and quit audio when this lecture is active.
              if (isLectureOn)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () {
                      provider.stopSharawyLecture();
                    },
                    icon: Icon(
                      Icons.stop_rounded,
                      color: AppColors.blackColor,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
