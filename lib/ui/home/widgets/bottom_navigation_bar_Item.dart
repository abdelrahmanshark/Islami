import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/app_colors.dart';

BottomNavigationBarItem bottomNavBarItem(
  int index,
  String label,
  String icon,
  int selectedIndex,
) {
  return BottomNavigationBarItem(
    icon: selectedIndex == index
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(66),
              color: AppColors.grayColor,
            ),
            child: SvgPicture.asset(icon, color: AppColors.whiteColor),
          )
        : SvgPicture.asset(icon),
    label: label,
  );
}
