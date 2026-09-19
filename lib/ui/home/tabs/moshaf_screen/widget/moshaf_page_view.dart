import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_text.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// One Mushaf page: Surah headers, flowing ayahs, and page number.
class MoshafPageView extends StatelessWidget {
  final MoshafPage page;
  final VoidCallback onLongPress;

  const MoshafPageView({
    super.key,
    required this.page,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
          ),
        ),
        // Height follows ayah content; no scroll inside the page.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoshafPageText(page: page),
            const SizedBox(height: 8),
            Text(
              '${page.pageNumber}',
              textAlign: TextAlign.center,
              style: AppStyles.blackBold14.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
