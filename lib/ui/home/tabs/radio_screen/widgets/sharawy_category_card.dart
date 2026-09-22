import 'package:flutter/material.dart';
import 'package:islami/models/sharawy_category.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Category card used in the الشعراوي categories list.
class SharawyCategoryCard extends StatelessWidget {
  final SharawyCategory category;
  final VoidCallback onTap;

  const SharawyCategoryCard({
    super.key,
    required this.category,
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
                category.titleAr,
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
