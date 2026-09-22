import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/downloads_view/widget/downloaded_audio_slider.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_mode_icon_button.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Player card for a downloaded reciter (same features as ReciterCard).
class DownloadedReciterPlayerCard extends StatelessWidget {
  const DownloadedReciterPlayerCard({
    super.key,
    required this.summary,
  });

  final DownloadedReciterSummary summary;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsViewModel>(
      builder: (context, viewModel, child) {
        final bool isReciterOn =
            viewModel.playingReciterId != null &&
            viewModel.playingReciterId == summary.reciterId;
        final bool isReciterPlaying = isReciterOn && viewModel.isPlaying;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: MediaQuery.heightOf(context) * (isReciterOn ? 0.22 : 0.14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              isReciterOn
                  ? Image.asset(AppAssets.activeRadioCard, fit: BoxFit.cover)
                  : Image.asset(AppAssets.inActiveRadioCard),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      summary.reciterName,
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
                          isActive: viewModel.isRepeatEnabled,
                          onPressed: viewModel.toggleRepeat,
                        ),
                      IconButton(
                        onPressed: viewModel.playPreviousDownload,
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: viewModel.playSelectedReciter,
                        icon: Icon(
                          isReciterPlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: viewModel.playNextDownload,
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      if (isReciterOn)
                        ReciterModeIconButton(
                          icon: Icons.playlist_play_rounded,
                          isActive: viewModel.isAutoNextEnabled,
                          onPressed: viewModel.toggleAutoNext,
                        ),
                    ],
                  ),
                  if (isReciterOn) const DownloadedAudioSlider(),
                ],
              ),
              // Stop and quit audio when this reciter is active.
              if (isReciterOn)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: viewModel.stopPlayback,
                    icon: const Icon(
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
