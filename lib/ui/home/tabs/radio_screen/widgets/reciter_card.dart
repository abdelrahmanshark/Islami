import 'package:flutter/material.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/ui/home/widgets/playback_speed_button.dart';
import 'package:provider/provider.dart';

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
        final String? playingSuraName =
            isReciterOn &&
                provider.currentSura >= 1 &&
                provider.currentSura <= QuranResources.arabicQuranSuras.length
            ? QuranResources.arabicQuranSuras[provider.currentSura - 1]
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
                      reciter.name ?? '',
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
                        onPressed: provider.stopReciter,
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
              // Shrinks the buttons on narrow screens instead of overflowing.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isReciterOn)
                      ReciterModeIconButton(
                        icon: Icons.repeat_one_rounded,
                        isActive: provider.isRepeatEnabled,
                        onPressed: provider.toggleRepeat,
                      ),
                    IconButton(
                      onPressed: () async {
                        final bool played = await provider.recitersBack(
                          reciter,
                        );
                        if (!played && context.mounted) {
                          showPlaybackFailureSnackBar(context);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: AppColors.blackColor,
                        size: 36,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final bool played = await provider.playReciter(reciter);
                        if (!played && context.mounted) {
                          showPlaybackFailureSnackBar(context);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      icon: AnimatedIconSwitcher(
                        child: Icon(
                          isReciterPlaying
                              ? Icons.pause
                              : Icons.play_arrow_rounded,
                          key: ValueKey(isReciterPlaying),
                          color: AppColors.blackColor,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final bool played = await provider.recitersNext(
                          reciter,
                        );
                        if (!played && context.mounted) {
                          showPlaybackFailureSnackBar(context);
                        }
                      },
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
                        isActive: provider.isAutoNextEnabled,
                        onPressed: provider.toggleAutoNext,
                      ),
                    if (isReciterOn)
                      PlaybackSpeedButton(
                        label: provider.playbackSpeedLabel,
                        onPressed: provider.cyclePlaybackSpeed,
                      ),
                  ],
                ),
              ),
              if (isReciterOn) const ReciterAudioSlider(),
            ],
          ),
        );
      },
    );
  }
}
