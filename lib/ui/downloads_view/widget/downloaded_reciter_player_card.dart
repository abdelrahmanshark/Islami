import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/downloads_view/widget/downloaded_audio_slider.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_mode_icon_button.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Compact player card for a downloaded reciter (no radio card backgrounds).
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
        final int? playingSuraId =
            isReciterOn ? viewModel.playingSuraId : null;
        final String? playingSuraName =
            playingSuraId != null &&
                    playingSuraId >= 1 &&
                    playingSuraId <= QuranResources.arabicQuranSuras.length
                ? QuranResources.arabicQuranSuras[playingSuraId - 1]
                : null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: EdgeInsets.fromLTRB(8, 8, 8, isReciterOn ? 6 : 8),
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isReciterOn ? 72 : 36,
                    ),
                    child: Text(
                      summary.reciterName,
                      style: AppStyles.blackBold16,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Stop playback when this reciter is active.
                  if (isReciterOn)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: viewModel.stopPlayback,
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
                  // Show current sura name in the top-right corner.
                  if (playingSuraName != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          playingSuraName,
                          style: AppStyles.blackBold14,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
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
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: AppColors.blackColor,
                      size: 36,
                    ),
                  ),
                  IconButton(
                    onPressed: viewModel.playSelectedReciter,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isReciterPlaying
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      color: AppColors.blackColor,
                      size: 40,
                    ),
                  ),
                  IconButton(
                    onPressed: viewModel.playNextDownload,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.blackColor,
                      size: 36,
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
        );
      },
    );
  }
}
