import 'package:flutter/material.dart';
import 'package:islami/models/radio_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/widgets/animated_icon_switcher.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class RadioCard extends StatelessWidget {
  final Radios radio;

  const RadioCard({super.key, required this.radio});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        final bool isRadioOn =
            provider.selectedRadioId != null &&
            provider.selectedRadioId == radio.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  radio.name ?? '',
                  style: AppStyles.blackBold16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      final bool played = await provider.playRadio(radio);
                      if (!played && context.mounted) {
                        showPlaybackFailureSnackBar(context);
                      }
                    },
                    visualDensity: VisualDensity.compact,
                    icon: AnimatedIconSwitcher(
                      child: Icon(
                        isRadioOn ? Icons.pause : Icons.play_arrow_rounded,
                        key: ValueKey(isRadioOn),
                        color: AppColors.blackColor,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
