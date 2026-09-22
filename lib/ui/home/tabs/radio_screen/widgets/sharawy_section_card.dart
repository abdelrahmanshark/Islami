import 'package:flutter/material.dart';
import 'package:islami/models/quran_story.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Section card used inside an opened Sha'rawy category.
class SharawySectionCard extends StatelessWidget {
  final QuranStorySection section;
  final VoidCallback onTap;

  const SharawySectionCard({
    super.key,
    required this.section,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
        height: MediaQuery.heightOf(context) * 0.14,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: AlignmentGeometry.bottomCenter,
          children: [
            Image.asset(AppAssets.inActiveRadioCard),
            Center(
              child: Text(
                section.title,
                style: AppStyles.blackBold18,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
