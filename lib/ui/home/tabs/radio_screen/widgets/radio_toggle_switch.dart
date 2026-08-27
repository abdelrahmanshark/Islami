import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:provider/provider.dart';

class RadioToggleSwitch extends StatelessWidget {
  const RadioToggleSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 15, vertical: 10),
      child: AnimatedToggleSwitch<int>.size(
        textDirection: TextDirection.ltr,
        current: context.watch<RadioViewModel>().toggleSwitchIndex,
        values: const [0, 1],
        iconList: [
          Text(
            'Radio',
            style: context.read<RadioViewModel>().switcherTextStyle(0),
          ),
          Text(
            'Reciters',
            style: context.read<RadioViewModel>().switcherTextStyle(1),
          ),
        ],
        onTap: (props) {
          if (props.tapped?.index == 0) {
            context.read<RadioViewModel>().getRadios();
          } else {
            context.read<RadioViewModel>().getReciters();
          }
        },
        iconOpacity: 1,
        indicatorSize: Size(MediaQuery.widthOf(context) * .5, double.infinity),
        borderWidth: 2.0,
        iconAnimationType: AnimationType.onHover,
        style: ToggleStyle(
          backgroundColor: AppColors.grayColor,
          indicatorColor: AppColors.primaryColor,
          borderColor: AppColors.blackColor,
          borderRadius: BorderRadius.circular(12),
        ),
        onChanged: (index) =>
            context.read<RadioViewModel>().changeToggleIndex(index),
      ),
    );
  }
}
