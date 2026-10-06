import 'package:flutter/material.dart';
import 'package:islami/services/quran_download_manager.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Persistent overlay so download progress/stop stay visible after navigation.
class DownloadProgressBanner extends StatelessWidget {
  const DownloadProgressBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranDownloadManager>(
      builder: (BuildContext context, QuranDownloadManager manager, _) {
        if (!manager.isDownloading) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: 12,
          right: 12,
          top: MediaQuery.paddingOf(context).top + 8,
          child: Material(
            color: AppColors.transparentColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.blackColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    manager.activeReciterName ?? 'تحميل القرآن',
                    style: AppStyles.primaryBold14,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manager.progressLabel ??
                        'جاري التحميل ${manager.downloadCompletedCount}/${manager.downloadTotalCount}',
                    style: AppStyles.whiteBold12,
                    textAlign: TextAlign.center,
                  ),
                  if (manager.currentFileProgressPercent != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: manager.currentFileProgressPercent! / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.grayColor,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (manager.isDownloadAll)
                        TextButton(
                          onPressed: manager.cancelAllDownloads,
                          child: Text(
                            'إيقاف الكل',
                            style: AppStyles.primaryBold14,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: manager.isDownloadAll
                            ? manager.cancelCurrentSuraDownload
                            : manager.cancelDownload,
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        label: Text(
                          manager.isDownloadAll
                              ? 'إيقاف السورة'
                              : 'إيقاف التحميل',
                          style: AppStyles.primaryBold14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
