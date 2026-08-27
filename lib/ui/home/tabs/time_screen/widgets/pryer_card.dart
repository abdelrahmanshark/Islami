import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

class PrayersCard extends StatelessWidget {
  Prayer prayer;

  PrayersCard({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.widthOf(context) * 0.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blackColor, AppColors.primaryColor],
          begin: AlignmentGeometry.topLeft,
          end: AlignmentGeometry.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            prayer.PryerName,
            style: AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          Text(
            prayer.PryerTime,
            style: AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
