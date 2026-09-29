import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/app_assets.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_styles.dart';

typedef OnChanged = void Function(String newText);

class SuraSearchBar extends StatelessWidget {
  /// Increases each time any search bar is tapped, so lists can scroll to top.
  static final ValueNotifier<int> activationCount = ValueNotifier<int>(0);

  final String? hintText;
  final TextDirection? textDirection;

  /// Optional widget shown at the end of the field (e.g. a menu).
  final Widget? suffixIcon;

  /// Optional SVG icon at the start of the field. Defaults to the Quran icon.
  final String? iconAsset;

  const SuraSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
    this.textDirection,
    this.suffixIcon,
    this.iconAsset,
  });
  final OnChanged onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(
          horizontal: 10
      ),
      child: TextField(
        onTap: () {
          activationCount.value++;
        },
        onChanged: (newText) {
          onChanged(newText);
        },
        textDirection: textDirection ?? TextDirection.ltr,
        style: AppStyles.primaryBold20,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: hintText ?? "اسم السورة",
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
            iconAsset ?? AppAssets.quranIc,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryColor,
              BlendMode.srcIn,
            ),
            fit: BoxFit.scaleDown,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
