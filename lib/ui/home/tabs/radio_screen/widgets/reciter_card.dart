import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/models/RecitersResponse.dart';
import 'package:provider/provider.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';
import '../radio_view_model.dart';

class ReciterCard extends StatelessWidget {
  Reciters reciter;

  ReciterCard({super.key, required this.reciter});

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
          bool isReciterOn = provider.selectedReciter == reciter;
          return Stack(
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
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
