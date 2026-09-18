import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_card.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_styles.dart';
import '../quran_screen/widgets/sura_search_bar.dart';

class RecitersScreen extends StatelessWidget {
  final int index;

  const RecitersScreen({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.transparentColor,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          backgroundColor: AppColors.grayColor,
          iconTheme: IconThemeData(color: AppColors.primaryColor),
          title: Text(
            QuranResources.arabicQuranSuras[index],
            style: AppStyles.primaryBold24,
          ),
          centerTitle: true,
        ),
        body: Consumer<RadioViewModel>(
          builder: (context, provider, child) {
            return Column(
              children: [
                if (provider.reciterIsLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else if (provider.reciterFailureMsg.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        provider.reciterFailureMsg,
                        style: AppStyles.primaryBold24,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 20,),
                        SuraSearchBar(
                          onChanged: (newText) {
                            provider.filterReciter(newText);
                          },
                          hintText: 'Shikh Search',
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 40,),
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.filteredReciters.length,
                            itemBuilder: (context, index) {
                              return ReciterCard(
                                reciter: provider.filteredReciters[index],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}