import 'package:flutter/material.dart';
import 'package:islami/providers/most_recent_provider.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_view_model.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/most_recently.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_bar.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';
import '../../../../utils/app_colors.dart';

class QuranScreen extends StatefulWidget {
  QuranScreen({super.key});
  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery
        .of(context)
        .size
        .width;
    var height = MediaQuery
        .of(context)
        .size
        .height;
    final mostRecentProvider = context.watch<MostRecentProvider>();
    return ChangeNotifierProvider(
      create: (context) => QuranViewModel(),
      child: Consumer<QuranViewModel>(
        builder: (context, provider, child) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.quranBg),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 10,
                  vertical: 6
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(AppAssets.header),
                  SuraSearchBar(onChanged: provider.onSearch),
                  SizedBox(height: 8),
                  Visibility(
                    visible: mostRecentProvider.mostRecentSuras.isNotEmpty,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text("Most Recently Searched",
                            style: AppStyles.whiteBold16),
                        SizedBox(height: 8),
                        SizedBox(
                          width: width * 0.8,
                          height: height * 0.174,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext context, int index) =>
                                InkWell(
                                    onTap: () {
                                      mostRecentProvider.saveSuraIndex(
                                          mostRecentProvider
                                              .mostRecentSuras[index]
                                          , context);
                                    },
                                    child: MostRecently(
                                        index: mostRecentProvider
                                            .mostRecentSuras[index])),
                            itemCount: mostRecentProvider.mostRecentSuras
                                .length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text("Suras List", style: AppStyles.whiteBold16),
                  provider.filterSearch.isEmpty ? Text(
                    "Sorry we cant find the sura",
                    style: AppStyles.whiteBold20,) :
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsetsGeometry.symmetric(vertical: 10),
                      itemBuilder: (BuildContext context, int index) =>
                          InkWell(
                            onTap: () {
                              provider.onSuraTap(
                                  provider.filterSearch[index], context);
                            },
                            child: SuraBar(index: provider.filterSearch[index]),
                          ),
                      separatorBuilder: (BuildContext context, int index) =>
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
            ),
          );
        },
      ),
    );
  }

}
