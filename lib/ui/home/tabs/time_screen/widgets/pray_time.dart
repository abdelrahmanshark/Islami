import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/pryer_card.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../models/TimeResponse.dart';

class PrayTime extends StatelessWidget {
  Timings? timing;

  DateInfo? dateInfo;

  PrayTime({super.key, required this.timing, required this.dateInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.heightOf(context) * .4,
      padding: EdgeInsetsGeometry.symmetric(vertical: 5),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.prayTimeBg),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 1),
              Column(
                children: [
                  Text(
                    dateInfo?.gregorian?.day ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                  Text(
                    dateInfo?.gregorian?.month?.en ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                  Text(
                    dateInfo?.gregorian?.year ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                ],
              ),
              SizedBox(width: 10),
              Column(
                children: [
                  Text('Pray Time', style: AppStyles.blackBold18),
                  Text(
                    dateInfo?.hijri?.weekday?.ar ?? '',
                    style: AppStyles.whiteBold20,
                  ),
                ],
              ),
              SizedBox(width: 1),
              Column(
                children: [
                  Text(
                    dateInfo?.hijri?.day ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                  Text(
                    dateInfo?.hijri?.month?.en ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                  Text(
                    dateInfo?.hijri?.year ?? '',
                    style: AppStyles.whiteBold16,
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: CarouselSlider(
              options: CarouselOptions(
                height: MediaQuery.heightOf(context) * .2,
                enlargeCenterPage: true,
                reverse: true,
                viewportFraction: .22,
                enlargeFactor: .1,
              ),
              items: List.generate(8, (index) => index).map((index) {
                return PrayersCard(
                  prayer: context.read<TimeViewModel>().pryerTimes[index],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
