import 'package:flutter/material.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_toggle_switch.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_select_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermons_list.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_list.dart';
import 'package:islami/ui/home/widgets/active_audio_list_view.dart';
import 'package:islami/ui/home/widgets/no_internet_retry_view.dart';
import 'package:islami/ui/home/widgets/offline_refresh_header.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RadioViewModel>().onTabOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.radioBg),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              OfflineRefreshHeader(
                onRefresh: provider.refreshCurrentOnlineData,
              ),
              RadioToggleSwitch(),
              SizedBox(height: 10),
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
                              onChanged: (newText) {
                                provider.filterRadio(newText);
                              },
                              hintText: 'بحث عن شيخ',
                              textDirection: TextDirection.rtl,
                            ),
                            Expanded(
                              child: ActiveAudioListView(
                                itemBuilder: (context, index) {
                                  return RadioCard(
                                    radio: provider.filteredRadios[index],
                                  );
                                },
                                itemCount: provider.filteredRadios.length,
                                activeIndex: provider.activeRadioIndex,
                                scrollRequested: provider.shouldScrollToActive(
                                  ActiveAudioType.radio,
                                ),
                                onScrollHandled: provider.onScrolledToActive,
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
                              onChanged: (newText) {
                                provider.filterReciter(newText);
                              },
                              hintText: 'بحث عن شيخ',
                              textDirection: TextDirection.rtl,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: provider.filteredReciters.length,
                                itemBuilder: (context, index) {
                                  final reciter =
                                      provider.filteredReciters[index];
                                  return ReciterSelectCard(
                                    reciter: reciter,
                                    onTap: () {
                                      provider.resetSuraSearch();
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.recitersRouteName,
                                        arguments: reciter,
                                      );
                                    },
                                  );
                                },
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
        );
      },
    );
  }
}
