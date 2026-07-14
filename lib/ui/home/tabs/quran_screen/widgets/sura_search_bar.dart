import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';

typedef OnChanged = void Function(String newText);

class SuraSearchBar extends StatelessWidget {
  SuraSearchBar({super.key, required this.onChanged});

  OnChanged onChanged;
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (newText) {
        onChanged(newText);
      },
      style: AppStyles.primaryBold20,
      cursorColor: AppColors.primaryColor,
      decoration: InputDecoration(
        hintText: "Sura Name",
        hintStyle: AppStyles.whiteBold16,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          gapPadding: 12,
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        enabled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          gapPadding: 12,
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          gapPadding: 12,
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        prefixIcon: SvgPicture.asset(
          AppAssets.quranIc,
          color: AppColors.primaryColor,
          fit: BoxFit.scaleDown,
        ),
      ),
    );
  }
}
