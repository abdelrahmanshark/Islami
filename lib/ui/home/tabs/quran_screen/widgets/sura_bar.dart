import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../utils/app_assets.dart';
import '../../../../../utils/app_styles.dart';
import '../quran_resources.dart';

class SuraBar extends StatelessWidget {
  int index;

  SuraBar({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(AppAssets.suraNumVector),
            Text('${index + 1}', style: AppStyles.whiteBold16),
          ],
        ),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              QuranResources.englishQuranSuras[index],
              style: AppStyles.whiteBold20,
            ),
            Text(
              '${QuranResources.AyaNumber[index]} verses',
              style: AppStyles.whiteBold12,
              textAlign: TextAlign.start,
            ),
          ],
        ),
        Spacer(),
        Text(
          QuranResources.arabicQuranSuras[index],
          style: AppStyles.whiteBold20,
        ),
      ],
    );
  }
}
