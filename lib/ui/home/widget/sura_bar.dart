import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:islami/models/quran_resources.dart';

import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';

class SuraBar extends StatelessWidget {
  final int index;

  const SuraBar({super.key, required this.index});

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
              QuranResources.arabicQuranSuras[index],
              style: AppStyles.whiteBold20,
            ),
            Text(
              '${QuranResources.ayaNumber[index]} آيات',
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