import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class NextPrayerBanner extends StatelessWidget {
  const NextPrayerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        final prayer = provider.nextPrayer;
        if (prayer == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.blackColor.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryColor, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                'الصلاة القادمة',
                style: AppStyles.primaryBold16,
              ),
              const SizedBox(height: 8),
              Text(
                prayer.PryerName,
                style: AppStyles.whiteBold20,
              ),
              const SizedBox(height: 4),
              Text(
                prayer.PryerTime,
                style: AppStyles.primaryBold20,
              ),
              const SizedBox(height: 12),
              Text(
                'متبقي',
                style: AppStyles.whiteBold14,
              ),
              const SizedBox(height: 4),
              Text(
                provider.remainingTimeFormatted,
                style: AppStyles.primaryBold24,
              ),
            ],
          ),
        );
      },
    );
  }
}
