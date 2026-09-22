import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';

/// Card used to pick a reciter before opening the sura list.
class ReciterSelectCard extends StatelessWidget {
  final Reciters reciter;
  final VoidCallback onTap;

  const ReciterSelectCard({
    super.key,
    required this.reciter,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  reciter.name ?? '',
                  style: AppStyles.blackBold18,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
