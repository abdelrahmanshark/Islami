import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Buttons above surah search: selected count download + download all.
class ReciterDownloadActionsBar extends StatelessWidget {
  const ReciterDownloadActionsBar({
    super.key,
    required this.selectedCount,
    required this.isDownloading,
    required this.progressLabel,
    required this.onDownloadSelected,
    required this.onDownloadAll,
    required this.onCancelDownload,
  });

  final int selectedCount;
  final bool isDownloading;
  final String? progressLabel;
  final VoidCallback onDownloadSelected;
  final VoidCallback onDownloadAll;
  final VoidCallback onCancelDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isDownloading || selectedCount == 0
                      ? null
                      : onDownloadSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.grayColor,
                    foregroundColor: AppColors.blackColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'تحميل المحدد ($selectedCount)',
                    style: AppStyles.blackBold14,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: isDownloading ? null : onDownloadAll,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryColor),
                    foregroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'تحميل كل السور',
                    style: AppStyles.primaryBold14,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (progressLabel != null)
                  Expanded(
                    child: Text(
                      progressLabel!,
                      style: AppStyles.primaryBold14,
                    ),
                  ),
                TextButton.icon(
                  onPressed: onCancelDownload,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: AppColors.primaryColor,
                  ),
                  label: Text(
                    'إيقاف التحميل',
                    style: AppStyles.primaryBold14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
