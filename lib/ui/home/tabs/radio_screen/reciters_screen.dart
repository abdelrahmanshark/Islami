import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_card.dart';
import 'package:islami/ui/home/widgets/sura_bar.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_colors.dart';
import '../../../../utils/app_styles.dart';

class RecitersScreen extends StatelessWidget {
  final Reciters reciter;

  const RecitersScreen({
    super.key,
    required this.reciter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.radioBg),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.transparentColor,
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            backgroundColor: AppColors.grayColor,
            iconTheme: IconThemeData(color: AppColors.primaryColor),
            title: Text(
              reciter.name ?? '',
              style: AppStyles.primaryBold24,
            ),
            centerTitle: true,
          ),
          body: Consumer<RadioViewModel>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  SizedBox(height: 12),
                  ReciterCard(reciter: reciter),
                  SizedBox(height: 12),
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
                            itemBuilder: (BuildContext context, int index) {
                              final suraIndex = provider.filterSearch[index];
                              return InkWell(
                                onTap: () {
                                  provider.playReciterSura(
                                    reciter,
                                    suraIndex + 1,
                                  );
                                },
                                child: SuraBar(index: suraIndex),
                              );
                            },
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
              );
            },
          ),
        ),
      ),
    );
  }
}
