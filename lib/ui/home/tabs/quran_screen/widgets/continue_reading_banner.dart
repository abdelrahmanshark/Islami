import 'package:flutter/material.dart';
import 'package:islami/models/quran_resources.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Banner on the Quran tab to resume reading from the saved ayah.
class ContinueReadingBanner extends StatelessWidget {
  final int suraIndex;
  final int ayahIndex;
  final VoidCallback onTap;

  const ContinueReadingBanner({
    super.key,
    required this.suraIndex,
    required this.ayahIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة القراءة',
                    style: AppStyles.primaryBold16,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${QuranResources.arabicQuranSuras[suraIndex]} — آية ${ayahIndex + 1}',
                    style: AppStyles.whiteBold14,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
