import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Opens the Qibla screen when tapped.
class QiblaBanner extends StatelessWidget {
  const QiblaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => provider.openQibla(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blackColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.explore,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'القبلة',
                  style: AppStyles.primaryBold16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
