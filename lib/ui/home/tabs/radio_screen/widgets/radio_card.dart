import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../models/RadioResponce.dart';

class RadioCard extends StatelessWidget {
  Radios radio;

  RadioCard({super.key, required this.radio});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
      height: MediaQuery.heightOf(context) * 0.14,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Consumer<RadioViewModel>(
        builder: (context, provider, child) {
          bool isRadioOn = provider.selectedRadio == radio;
          bool isSoundON = provider.selectedRadioForSound != radio;
          return Stack(
            alignment: AlignmentGeometry.bottomCenter,
            children: [
              isRadioOn
                  ? Image.asset(AppAssets.activeRadioCard, fit: BoxFit.cover)
                  : Image.asset(AppAssets.inActiveRadioCard),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: [
                  Expanded(
                    child: Text(
                      radio.name ?? '',
                      style: AppStyles.blackBold18,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 55),
                      IconButton(
                        onPressed: () {
                          provider.playRadio(radio);
                        },
                        icon: Icon(
                          isRadioOn ? Icons.pause : Icons.play_arrow_rounded,
                          color: AppColors.blackColor,
                          size: 50,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          provider.muteSound(radio);
                        },
                        icon: Icon(
                          isSoundON ? Icons.volume_up : Icons.volume_off,
                          color: AppColors.blackColor,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
