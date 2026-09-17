import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/models/prayer.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

class PrayersCard extends StatelessWidget {
  final Prayer prayer;
  final bool isNext;

  const PrayersCard({
    super.key,
    required this.prayer,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: MediaQuery.widthOf(context) * 0.22,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNext
              ? [AppColors.primaryColor, AppColors.blackColor]
              : [AppColors.blackColor, AppColors.primaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isNext
            ? Border.all(color: AppColors.whiteColor, width: 2)
            : null,
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            prayer.PryerName,
            style: isNext ? AppStyles.blackBold14 : AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          Text(
            prayer.PryerTime,
            style: isNext ? AppStyles.whiteBold16 : AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          if (isNext)
            Text(
              'القادمة',
              style: AppStyles.whiteBold12,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
