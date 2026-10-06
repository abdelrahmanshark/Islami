import 'package:flutter/material.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Seek slider for offline download playback.
class DownloadedAudioSlider extends StatefulWidget {
  const DownloadedAudioSlider({super.key});

  @override
  State<DownloadedAudioSlider> createState() => _DownloadedAudioSliderState();
}

class _DownloadedAudioSliderState extends State<DownloadedAudioSlider> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final DownloadsViewModel viewModel = context.read<DownloadsViewModel>();

    return StreamBuilder<Duration?>(
      stream: viewModel.player.durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: viewModel.player.positionStream,
          builder: (context, positionSnapshot) {
            final Duration duration =
                durationSnapshot.data ?? Duration.zero;
            final Duration position =
                positionSnapshot.data ?? Duration.zero;
            final double maxMs = duration.inMilliseconds.toDouble();
            final double currentMs =
                (_dragValueMs ?? position.inMilliseconds.toDouble())
                    .clamp(0, maxMs < 1 ? 1 : maxMs);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      padding: EdgeInsets.zero,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppColors.blackColor,
                      inactiveTrackColor: AppColors.grayColor,
                      thumbColor: AppColors.blackColor,
                      overlayColor:
                          AppColors.blackColor.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      min: 0,
                      max: maxMs < 1 ? 1 : maxMs,
                      value: currentMs.toDouble(),
                      onChanged: maxMs < 1
                          ? null
                          : (value) {
                              setState(() {
                                _dragValueMs = value;
                              });
                            },
                      onChangeEnd: maxMs < 1
                          ? null
                          : (value) {
                              viewModel.seekPlayback(
                                Duration(milliseconds: value.round()),
                              );
                              setState(() {
                                _dragValueMs = null;
                              });
                            },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        viewModel.formatAudioTime(
                          Duration(milliseconds: currentMs.round()),
                        ),
                        style: AppStyles.blackBold14,
                      ),
                      Text(
                        viewModel.formatAudioTime(duration),
                        style: AppStyles.blackBold14,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
