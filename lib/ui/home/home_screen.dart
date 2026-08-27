import 'package:flutter/material.dart';
import 'package:islami/ui/home/home_screen_view_model.dart';
import 'package:islami/ui/home/widgets/bottom_navigation_bar_Item.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeScreenViewModel homeScreenViewModel = HomeScreenViewModel();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => homeScreenViewModel,
      child: Consumer<HomeScreenViewModel>(
        builder: (context, value, child) {
          return SafeArea(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: homeScreenViewModel.tabs[homeScreenViewModel.selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: homeScreenViewModel.selectedIndex,
                onTap: (index) {
                  homeScreenViewModel.updateIndex(index);
                },
                items: [
                  bottomNavBarItem(0, 'Quran', AppAssets.quranIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(1, 'Hadith', AppAssets.hadithIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(2, 'Sebha', AppAssets.sebhaIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(3, 'Radio', AppAssets.radioIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(4, 'Time', AppAssets.timeIc,
                      homeScreenViewModel.selectedIndex),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


}
