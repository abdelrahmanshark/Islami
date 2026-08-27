import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';

typedef OnChanged = void Function(String newText);

class SuraSearchBar extends StatelessWidget {
  String? hintText;
  TextDirection? textDirection;

  SuraSearchBar(
      {super.key, required this.onChanged, this.hintText, this.textDirection});
  OnChanged onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(
          horizontal: 10
      ),
      child: TextField(
        onChanged: (newText) {
          onChanged(newText);
        },
        textDirection: textDirection ?? TextDirection.ltr,
        style: AppStyles.primaryBold20,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: hintText ?? "Sura Name",
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
      ),
    );
  }
}
