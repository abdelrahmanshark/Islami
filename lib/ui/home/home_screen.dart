import 'package:flutter/material.dart';
import 'package:islami/ui/downloads_view/downloads_view.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_screen.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_hub_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_screen.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_screen.dart';
import 'package:islami/ui/home/tabs/time_screen/time_screen.dart';
import 'package:islami/ui/home/view_model/home_screen_view_model.dart';
import 'package:islami/ui/home/widget/bottom_navigation_bar_item.dart';
import 'package:islami/ui/home/widget/home_tabs_view.dart';
import 'package:islami/ui/home/widget/mini_audio_player.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeScreenViewModel homeScreenViewModel = HomeScreenViewModel();

  // Order must match the bottom bar items and HomeScreenViewModel indexes.
  final List<Widget> _tabs = [
    const MoshafHubView(),
    const HadithScreen(),
    SebhaScreen(),
    RadioScreen(),
    DownloadsView(),
    TimeScreen(),
  ];

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
              body: HomeTabsView(
                selectedIndex: homeScreenViewModel.selectedIndex,
                tabs: _tabs,
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniAudioPlayer(),
                  BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: homeScreenViewModel.selectedIndex,
                    onTap: (index) {
                      homeScreenViewModel.updateIndex(index);
                    },
                    items: [
                      bottomNavBarItem(
                        0,
                        'مصحف',
                        AppAssets.quranIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                      bottomNavBarItem(
                        1,
                        'حديث',
                        AppAssets.hadithIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                      bottomNavBarItem(
                        2,
                        'سبحة',
                        AppAssets.sebhaIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                      bottomNavBarItem(
                        3,
                        'راديو',
                        AppAssets.radioIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                      bottomNavBarItem(
                        4,
                        'تحميلات',
                        AppAssets.downloadIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                      bottomNavBarItem(
                        5,
                        'مواقيت',
                        AppAssets.timeIc,
                        homeScreenViewModel.selectedIndex,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
