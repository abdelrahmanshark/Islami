import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
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
                    padding: const EdgeInsets.symmetric(horizontal: 36),
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
                ],
              ),
              Row(
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
                      final bool played = await provider.recitersBack(reciter);
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
                    icon: Icon(
                      isReciterPlaying
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                      color: AppColors.blackColor,
                      size: 40,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final bool played = await provider.recitersNext(reciter);
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
                ],
              ),
              if (isReciterOn) const ReciterAudioSlider(),
            ],
          ),
        );
      },
    );
  }
}
