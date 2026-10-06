import 'package:flutter/material.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/ui/home/view_model/home_screen_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/view_model/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/favorite_list_tabs.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/favorite_move_transition.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/radio_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/radio_toggle_switch.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/reciter_select_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/sermons_list.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/sharawy_list.dart';
import 'package:islami/ui/home/widget/active_audio_list_view.dart';
import 'package:islami/ui/home/widget/no_internet_retry_view.dart';
import 'package:islami/ui/home/widget/offline_refresh_header.dart';
import 'package:islami/ui/home/widget/sura_search_bar.dart';
import 'package:islami/ui/widget/fade_in.dart';
import 'package:islami/ui/widget/screen_background.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import 'package:islami/utils/app_assets.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  late final HomeScreenViewModel _homeViewModel;

  @override
  void initState() {
    super.initState();
    _homeViewModel = context.read<HomeScreenViewModel>();
    _homeViewModel.addListener(_onHomeTabChanged);
    // Runs after the first frame because it notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RadioViewModel>().onTabOpened();
    });
  }

  @override
  void dispose() {
    _homeViewModel.removeListener(_onHomeTabChanged);
    super.dispose();
  }

  /// Refreshes shared settings each time the user comes back to this tab.
  void _onHomeTabChanged() {
    if (_homeViewModel.selectedIndex != HomeScreenViewModel.radioTabIndex) {
      return;
    }
    context.read<RadioViewModel>().onTabOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        return ScreenBackground(
          image: AppAssets.radioBg,
          child: Column(
            children: [
              OfflineRefreshHeader(
                onRefresh: provider.refreshCurrentOnlineData,
              ),
              RadioToggleSwitch(),
              SizedBox(height: 10),
              // Fades the new segment in when the toggle changes.
              Expanded(
                child: FadeIn(
                  key: ValueKey(provider.toggleSwitchIndex),
                  child: Column(
                    children: [
                      if (provider.toggleSwitchIndex == 0)
                        provider.radioIsLoading
                            ? Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : provider.radioFailureMsg.isNotEmpty
                            ? Expanded(
                                child: NoInternetRetryView(
                                  message: provider.radioFailureMsg,
                                  onRefresh: provider.getRadios,
                                ),
                              )
                            : Expanded(
                                child: Column(
                                  children: [
                                    SuraSearchBar(
                                      text: provider.radioSearchQuery,
                                      onChanged: (newText) {
                                        provider.filterRadio(newText);
                                      },
                                      hintText: 'بحث عن شيخ',
                                      textDirection: TextDirection.rtl,
                                    ),
                                    FavoriteListTabs(
                                      selectedIndex: provider.radioListTabIndex,
                                      onChanged: provider.changeRadioListTab,
                                    ),
                                    Expanded(
                                      child: FadeIn(
                                        key: ValueKey(
                                          provider.radioListTabIndex,
                                        ),
                                        child:
                                            provider.filteredRadios.isEmpty &&
                                                provider.radioListTabIndex ==
                                                    RadioViewModel
                                                        .favoritesListTabIndex
                                            ? Center(
                                                child: Text(
                                                  'لا توجد إذاعات في المفضلة',
                                                  style: AppStyles.whiteBold20,
                                                ),
                                              )
                                            : ActiveAudioListView(
                                                itemBuilder: (context, index) {
                                                  final radio = provider
                                                      .filteredRadios[index];
                                                  return FavoriteMoveTransition(
                                                    key: ValueKey(radio.id),
                                                    isLeaving: provider
                                                        .leavingRadioIds
                                                        .contains(radio.id),
                                                    isEntering:
                                                        provider
                                                            .enteringRadioId ==
                                                        radio.id,
                                                    child: RadioCard(
                                                      radio: radio,
                                                    ),
                                                  );
                                                },
                                                itemCount: provider
                                                    .filteredRadios
                                                    .length,
                                                activeIndex:
                                                    provider.activeRadioIndex,
                                                scrollRequested: provider
                                                    .shouldScrollToActive(
                                                      ActiveAudioType.radio,
                                                    ),
                                                onScrollHandled:
                                                    provider.onScrolledToActive,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                      else if (provider.toggleSwitchIndex == 1)
                        provider.reciterIsLoading
                            ? Expanded(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : provider.reciterFailureMsg.isNotEmpty
                            ? Expanded(
                                child: NoInternetRetryView(
                                  message: provider.reciterFailureMsg,
                                  onRefresh: provider.getReciters,
                                ),
                              )
                            : Expanded(
                                child: Column(
                                  children: [
                                    SuraSearchBar(
                                      text: provider.reciterSearchQuery,
                                      onChanged: (newText) {
                                        provider.filterReciter(newText);
                                      },
                                      hintText: 'بحث عن شيخ',
                                      textDirection: TextDirection.rtl,
                                    ),
                                    FavoriteListTabs(
                                      selectedIndex:
                                          provider.reciterListTabIndex,
                                      onChanged: provider.changeReciterListTab,
                                    ),
                                    Expanded(
                                      child: FadeIn(
                                        key: ValueKey(
                                          provider.reciterListTabIndex,
                                        ),
                                        child:
                                            provider.filteredReciters.isEmpty &&
                                                provider.reciterListTabIndex ==
                                                    RadioViewModel
                                                        .favoritesListTabIndex
                                            ? Center(
                                                child: Text(
                                                  'لا يوجد قراء في المفضلة',
                                                  style: AppStyles.whiteBold20,
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: provider
                                                    .filteredReciters
                                                    .length,
                                                itemBuilder: (context, index) {
                                                  final reciter = provider
                                                      .filteredReciters[index];
                                                  return FavoriteMoveTransition(
                                                    key: ValueKey(reciter.id),
                                                    isLeaving: provider
                                                        .leavingReciterIds
                                                        .contains(reciter.id),
                                                    isEntering:
                                                        provider
                                                            .enteringReciterId ==
                                                        reciter.id,
                                                    child: ReciterSelectCard(
                                                      reciter: reciter,
                                                      isFavorite: provider
                                                          .isReciterFavorite(
                                                            reciter,
                                                          ),
                                                      onFavoritePressed: () =>
                                                          provider
                                                              .toggleFavoriteReciter(
                                                                reciter,
                                                              ),
                                                      onTap: () {
                                                        provider
                                                            .resetSuraSearch();
                                                        Navigator.pushNamed(
                                                          context,
                                                          AppRoutes
                                                              .recitersRouteName,
                                                          arguments: reciter,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                      else if (provider.toggleSwitchIndex == 2)
                        const SermonsList()
                      else
                        const SharawyList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
