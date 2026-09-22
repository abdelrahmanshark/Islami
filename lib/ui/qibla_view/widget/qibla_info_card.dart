import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Shows Qibla angle and Arabic instructions under the compass.
class QiblaInfoCard extends StatelessWidget {
  final String offsetText;
  final String instructionText;
  final bool isFacingQibla;

  const QiblaInfoCard({
    super.key,
    required this.offsetText,
    required this.instructionText,
    required this.isFacingQibla,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.blackColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFacingQibla
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'اتجاه القبلة',
            style: AppStyles.primaryBold16,
          ),
          const SizedBox(height: 8),
          Text(
            offsetText,
            style: AppStyles.primaryBold24,
          ),
          const SizedBox(height: 12),
          Text(
            instructionText,
            style: AppStyles.whiteBold16,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
