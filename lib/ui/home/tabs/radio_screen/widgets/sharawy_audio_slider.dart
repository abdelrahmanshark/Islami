import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Slider and time labels for the active Sha'rawy lecture.
class SharawyAudioSlider extends StatefulWidget {
  const SharawyAudioSlider({super.key});

  @override
  State<SharawyAudioSlider> createState() => _SharawyAudioSliderState();
}

class _SharawyAudioSliderState extends State<SharawyAudioSlider> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<RadioViewModel>();

    return StreamBuilder<Duration?>(
      stream: viewModel.player.durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: viewModel.player.positionStream,
          builder: (context, positionSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final position = positionSnapshot.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds.toDouble();
            final currentMs =
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
                      overlayColor: AppColors.blackColor.withValues(alpha: 0.2),
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
                              viewModel.seekSharawyLecture(
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
