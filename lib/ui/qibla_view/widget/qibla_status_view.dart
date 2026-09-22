import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Shows loading or error/permission messages for the Qibla screen.
class QiblaStatusView extends StatelessWidget {
  final bool isLoading;
  final String message;
  final VoidCallback? onRetry;

  const QiblaStatusView({
    super.key,
    required this.isLoading,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore_off,
              color: AppColors.primaryColor,
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppStyles.primaryBold20,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.blackColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppStyles.blackBold16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
