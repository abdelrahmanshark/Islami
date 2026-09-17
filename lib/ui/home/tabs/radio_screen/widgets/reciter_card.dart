import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';
import '../radio_view_model.dart';
import 'reciter_audio_slider.dart';

class ReciterCard extends StatelessWidget {
  final Reciters reciter;

  ReciterCard({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        bool isReciterOn = provider.selectedReciter == reciter;
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
                          isReciterOn ? Icons.pause : Icons.play_arrow_rounded,
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
                    ],
                  ),
                  if (isReciterOn) const ReciterAudioSlider(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
