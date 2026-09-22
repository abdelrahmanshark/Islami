import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';
import '../radio_view_model.dart';
import 'reciter_audio_slider.dart';
import 'reciter_mode_icon_button.dart';

class ReciterCard extends StatelessWidget {
  final Reciters reciter;

  const ReciterCard({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        final isReciterOn =
            provider.selectedReciterId != null &&
            provider.selectedReciterId == reciter.id;
        final isReciterPlaying = isReciterOn && provider.isReciterPlaying;
        return Container(
          margin: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
          height: MediaQuery.heightOf(context) * (isReciterOn ? 0.22 : 0.14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: AlignmentGeometry.bottomCenter,
            children: [
              isReciterOn
                  ? Image.asset(AppAssets.activeRadioCard, fit: BoxFit.cover)
                  : Image.asset(AppAssets.inActiveRadioCard),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: [
                  Expanded(
                    child: Text(
                      reciter.name ?? '',
                      style: AppStyles.blackBold18,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isReciterOn)
                        ReciterModeIconButton(
                          icon: Icons.repeat_one_rounded,
                          isActive: provider.isRepeatEnabled,
                          onPressed: () {
                            provider.toggleRepeat();
                          },
                        ),
                      IconButton(
                        onPressed: () {
                          provider.recitersBack(reciter);
                        },
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          provider.playReciter(reciter);
                        },
                        icon: Icon(
                          isReciterPlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          provider.recitersNext(reciter);
                        },
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      if (isReciterOn)
                        ReciterModeIconButton(
                          icon: Icons.playlist_play_rounded,
                          isActive: provider.isAutoNextEnabled,
                          onPressed: () {
                            provider.toggleAutoNext();
                          },
                        ),
                    ],
                  ),
                  if (isReciterOn) const ReciterAudioSlider(),
                ],
              ),
              // Stop and quit audio when this reciter is active.
              if (isReciterOn)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () {
                      provider.stopReciter();
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
