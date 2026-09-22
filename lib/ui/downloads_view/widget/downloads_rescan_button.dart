import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';

/// Icon button that rescans device storage for existing Quran downloads.
class DownloadsRescanButton extends StatelessWidget {
  const DownloadsRescanButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: 'تحديث التحميلات',
      icon: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryColor,
              ),
            )
          : const Icon(
              Icons.refresh,
              color: AppColors.primaryColor,
              size: 28,
            ),
    );
  }
}
