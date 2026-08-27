import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/radio_toggle_switch.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_card.dart';
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
                SizedBox(height: 10,),
                provider.toggleSwitchIndex == 0
                    ? provider.radioIsLoading
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
                      SuraSearchBar(onChanged: (newText) {
                        provider.filterRadio(newText);
                      },
                          hintText: 'Shikh Search',
                          textDirection: TextDirection.rtl),
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
                    : provider.reciterIsLoading
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
                      SuraSearchBar(onChanged: (newText) {
                        provider.filterReciter(newText);
                      },
                        hintText: 'Shikh Search',
                        textDirection: TextDirection.rtl,),
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return ReciterCard(
                                reciter: provider.filteredReciters[index]);
                          },
                          itemCount: provider.filteredReciters.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
