import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_screen.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_screen.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_screen.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_screen.dart';
import 'package:islami/ui/home/tabs/time_screen/time_screen.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  List<Widget> tabs = [
    QuranScreen(),
    HadithScreen(),
    SebhaScreen(),
    RadioScreen(),
    TimeScreen(),
  ];
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: tabs[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          selectedIndex = index;
          setState(() {

          });
        },
        items: [
          bottomNavBarItem(0, 'Quran', AppAssets.quranIc),
          bottomNavBarItem(1, 'Hadith', AppAssets.hadithIc),
          bottomNavBarItem(2, 'Sebha', AppAssets.sebhaIc),
          bottomNavBarItem(3, 'Radio', AppAssets.radioIc),
          bottomNavBarItem(4, 'Time', AppAssets.timeIc),
        ],
      ),
    );
  }

  BottomNavigationBarItem bottomNavBarItem(int index, String label,
      String icon) {
    return BottomNavigationBarItem(
      icon: selectedIndex == index ? Container(
          padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6
          ),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(66),
              color: AppColors.grayColor
          ),
          child: SvgPicture.asset(
            icon,
            color: AppColors.whiteColor,
          )
      ) : SvgPicture.asset(icon),
      label: label,
    );
  }
}
