import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_card.dart';
import 'package:islami/ui/widgets/screen_background.dart';
import 'package:islami/utils/app_assets.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // heightOf only rebuilds on size changes (not keyboard/padding changes).
    var height = MediaQuery.heightOf(context);
    return ScreenBackground(
      image: AppAssets.hadithBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Image.asset(AppAssets.header),
          Expanded(
            child: CarouselSlider(
                options: CarouselOptions(
                  height: height * 0.7,
                  enlargeCenterPage: true,
                ),
                items: List.generate(50, (index) => index + 1,).map((index) {
                  return HadithCard(index: index);
                }).toList()
            ),
          )


        ],

      ),
    );
  }
}
