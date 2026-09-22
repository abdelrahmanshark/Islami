import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/reciters_screen.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_toggle_switch.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermons_list.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_list.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';
import '../quran_screen/widgets/sura_bar.dart';

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
                  Expanded(
                    child: Column(
                      children: [
                        SuraSearchBar(
                          onChanged: provider.onSearch,
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 12),
                        provider.filterSearch.isEmpty
                            ? Text(
                                "عذراً، لم نتمكن من العثور على السورة",
                                style: AppStyles.whiteBold20,
                              )
                            : Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsetsGeometry.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  itemBuilder:
                                      (BuildContext context, int index) =>
                                          InkWell(
                                            onTap: () {
                                              provider.updateCurrentSura(
                                                provider.filterSearch[index] +
                                                    1,
                                              );
                                              provider.resetReciterSearch();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) {
                                                    return ChangeNotifierProvider
                                                        .value(
                                                      value: provider,
                                                      child: RecitersScreen(
                                                        index: provider
                                                            .filterSearch[index],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                            child: SuraBar(
                                              index:
                                                  provider.filterSearch[index],
                                            ),
                                          ),
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 12,
                                            ),
                                            height: 2,
                                            width: double.infinity,
                                            color: AppColors.whiteColor,
                                          ),
                                  itemCount: provider.filterSearch.length,
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
