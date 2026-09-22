import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/reciters_screen.dart';
import 'package:islami/ui/home/tabs/radio_screen/view_model/reciter_download_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_toggle_switch.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_select_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermons_list.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_list.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RadioViewModel(),
      child: Consumer<RadioViewModel>(
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
                Image.asset(AppAssets.header),
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
                          child: Center(
                            child: Text(
                              provider.radioFailureMsg,
                              style: AppStyles.primaryBold24,
                            ),
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
                                child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    return RadioCard(
                                      radio: provider.filteredRadios[index],
                                    );
                                  },
                                  itemCount: provider.filteredRadios.length,
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
                          child: Center(
                            child: Text(
                              provider.reciterFailureMsg,
                              style: AppStyles.primaryBold24,
                            ),
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
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) {
                                              return MultiProvider(
                                                providers: [
                                                  ChangeNotifierProvider
                                                      .value(
                                                    value: provider,
                                                  ),
                                                  ChangeNotifierProvider(
                                                    create: (_) =>
                                                        ReciterDownloadViewModel(
                                                      reciter: reciter,
                                                    ),
                                                  ),
                                                ],
                                                child: RecitersScreen(
                                                  reciter: reciter,
                                                ),
                                              );
                                            },
                                          ),
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
      ),
    );
  }
}
