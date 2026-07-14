import 'package:flutter/material.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../../utils/app_styles.dart';

class MostRecently extends StatelessWidget {
  int index;
  late double width;
  late double height;

  MostRecently({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.all(6),
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 7),
      width: width * 0.8,
      height: height * 0.174,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.primaryColor,
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text("Al-Fatiha", style: AppStyles.blackBold24),
              Text("الفاتحة", style: AppStyles.blackBold24),
              Text("7 verses", style: AppStyles.blackBold14),
            ],
          ),
          Spacer(),
          Image.asset(AppAssets.quranMR),
        ],
      ),
    );
  }
}
