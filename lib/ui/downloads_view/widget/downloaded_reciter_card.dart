import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Compact card for a reciter that has offline downloads.
class DownloadedReciterCard extends StatelessWidget {
  const DownloadedReciterCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final DownloadedReciterSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              summary.reciterName,
              style: AppStyles.blackBold16,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${summary.suraCount} سورة',
              style: AppStyles.blackBold14,
            ),
          ],
        ),
      ),
    );
  }
}
