import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_reciter_summary.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Card for a reciter that has offline downloads.
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: MediaQuery.heightOf(context) * 0.12,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Image.asset(AppAssets.inActiveRadioCard),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      summary.reciterName,
                      style: AppStyles.blackBold18,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.suraCount} سورة',
                      style: AppStyles.blackBold14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
