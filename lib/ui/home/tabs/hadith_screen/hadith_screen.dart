import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_card.dart';
import 'package:islami/utils/app_assets.dart';

class HadithScreen extends StatelessWidget {
  HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery
        .of(context)
        .size
        .height;
    var width = MediaQuery
        .of(context)
        .size
        .width;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.hadithBg),
          fit: BoxFit.cover,
        ),
      ),
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
