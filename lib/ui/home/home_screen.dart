import 'package:flutter/material.dart';
import 'package:islami/ui/home/home_screen_view_model.dart';
import 'package:islami/ui/home/widgets/bottom_navigation_bar_Item.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
            top: false,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: homeScreenViewModel.tabs[homeScreenViewModel.selectedIndex],
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: homeScreenViewModel.selectedIndex,
                onTap: (index) {
                  homeScreenViewModel.updateIndex(index);
                },
                items: [
                  bottomNavBarItem(0, 'قرآن', AppAssets.quranIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(1, 'حديث', AppAssets.hadithIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(2, 'سبحة', AppAssets.sebhaIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(3, 'راديو', AppAssets.radioIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarItem(4, 'مواقيت', AppAssets.timeIc,
                      homeScreenViewModel.selectedIndex),
                  bottomNavBarIconItem(5, 'مصحف', Icons.menu_book,
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
