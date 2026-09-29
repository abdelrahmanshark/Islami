import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// "سبحة" / "أذكار وأدعية" switch at the top of the sebha tab.
class SebhaToggleSwitch extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SebhaToggleSwitch({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  /// Text style of a switch label, highlighted when it is selected.
  TextStyle _labelStyle(int index) {
    if (selectedIndex == index) {
      return AppStyles.blackBold18.copyWith(fontSize: 17);
    }
    return AppStyles.whiteBold16;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: AnimatedToggleSwitch<int>.size(
        textDirection: TextDirection.rtl,
        current: selectedIndex,
        values: const [
          SebhaViewModel.sebhaTabIndex,
          SebhaViewModel.azkarTabIndex,
        ],
        iconList: [
          Text('سبحة', style: _labelStyle(SebhaViewModel.sebhaTabIndex)),
          Text(
            'أذكار وأدعية',
            style: _labelStyle(SebhaViewModel.azkarTabIndex),
          ),
        ],
        iconOpacity: 1,
        indicatorSize: Size(MediaQuery.widthOf(context) / 2.2, double.infinity),
        borderWidth: 2.0,
        iconAnimationType: AnimationType.onHover,
        style: ToggleStyle(
          backgroundColor: AppColors.grayColor,
          indicatorColor: AppColors.primaryColor,
          borderColor: AppColors.blackColor,
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
