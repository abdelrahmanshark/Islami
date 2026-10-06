import 'package:flutter/material.dart';
import 'package:islami/ui/home/widget/bottom_nav_icon.dart';

/// Builds one bottom bar item with an animated selected icon.
BottomNavigationBarItem bottomNavBarItem(
  int index,
  String label,
  String icon,
  int selectedIndex,
) {
  return BottomNavigationBarItem(
    icon: BottomNavIcon(icon: icon, isSelected: selectedIndex == index),
    label: label,
  );
}
