import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/pryer_card.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../models/TimeResponse.dart';

class PrayTime extends StatelessWidget {
  final Timings? timing;
  final DateInfo? dateInfo;

  const PrayTime({super.key, required this.timing, required this.dateInfo});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        var prayers = provider.pryerTimes;
        int nextPrayerIndex = provider.nextPrayerIndex;

        return Container(
          width: double.infinity,
          height: MediaQuery.heightOf(context) * 0.38,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.prayTimeBg),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          dateInfo?.gregorian?.day ?? '',
                          style: AppStyles.whiteBold16,
                        ),
                        Text(
                          dateInfo?.gregorian?.month?.en ?? '',
                          style: AppStyles.whiteBold14,
                        ),
                        Text(
                          dateInfo?.gregorian?.year ?? '',
                          style: AppStyles.whiteBold12,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Pray Time', style: AppStyles.blackBold18),
                        const SizedBox(height: 4),
                        Text(
                          dateInfo?.hijri?.weekday?.ar ?? '',
                          style: AppStyles.whiteBold20,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          dateInfo?.hijri?.day ?? '',
                          style: AppStyles.whiteBold16,
                        ),
                        Text(
                          dateInfo?.hijri?.month?.ar ??
                              dateInfo?.hijri?.month?.en ??
                              '',
                          style: AppStyles.whiteBold14,
                        ),
                        Text(
                          dateInfo?.hijri?.year ?? '',
                          style: AppStyles.whiteBold12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: prayers.isEmpty
                    ? const SizedBox.shrink()
                    : CarouselSlider.builder(
                        itemCount: prayers.length,
                        options: CarouselOptions(
                          height: MediaQuery.heightOf(context) * 0.2,
                          enlargeCenterPage: true,
                          reverse: true,
                          viewportFraction: 0.24,
                          enlargeFactor: 0.15,
                          initialPage:
                              nextPrayerIndex >= 0 ? nextPrayerIndex : 0,
                        ),
                        itemBuilder: (context, index, realIndex) {
                          return PrayersCard(
                            prayer: prayers[index],
                            isNext: index == nextPrayerIndex,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
