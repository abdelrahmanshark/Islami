import 'package:flutter/material.dart';
import 'package:islami/models/sermon.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermon_audio_slider.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/utils/app_assets.dart';
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
          margin: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
          height: MediaQuery.heightOf(context) * (isSermonOn ? 0.24 : 0.14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: AlignmentGeometry.bottomCenter,
            children: [
              isSermonOn
                  ? Image.asset(AppAssets.activeRadioCard, fit: BoxFit.cover)
                  : Image.asset(AppAssets.inActiveRadioCard),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      sermon.titleAr,
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
                              await provider.playSermon(sermon);
                          if (!played && context.mounted) {
                            showPlaybackFailureSnackBar(context);
                          }
                        },
                        icon: Icon(
                          isSermonPlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      if (isSermonOn)
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
                  if (isSermonOn) const SermonAudioSlider(),
                ],
              ),
              // Stop and quit audio when this sermon is active.
              if (isSermonOn)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () {
                      provider.stopSermon();
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
