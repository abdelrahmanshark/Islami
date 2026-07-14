import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/most_recently.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_bar.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_styles.dart';

import '../../../../utils/app_assets.dart';
import '../../../../utils/app_colors.dart';

class QuranScreen extends StatefulWidget {
  QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<int> filterSearch = List.generate(114, (index) => index);

  late double width;

  late double height;

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.quranBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppAssets.header),
            SuraSearchBar(onChanged: onSearch),
            SSizedBox(height: 8),
            Text("Most Recently Searched", style: AppStyles.whiteBold16),
            SizedBox(height: 8),
            SizedBox(
              width: width * 0.8,
              height: height * 0.174,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) =>
                    MostRecently(index: index),
                itemCount: 5,
              ),
            ),
            Text("Suras List", style: AppStyles.whiteBold16),
            filterSearch.isEmpty ? Text(
              "Sorry we couldnt find the sura", style: AppStyles.whiteBold20,) :
            Expanded(
              child: ListView.separated(
                padding: EdgeInsetsGeometry.symmetric(vertical: 10),
                itemBuilder: (BuildContext context, int index) => InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.soraDetailsRouteName,
                      arguments: filterSearch[index],
                    );
                  },
                  child: SuraBar(index: filterSearch[index]),
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
                itemCount: filterSearch.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onSearch(String newText) {
    List<int> SuraResSearch = [];
    for (int i = 0; i < QuranResources.englishQuranSuras.length; i++) {
      if (QuranResources.englishQuranSuras[i].toUpperCase().contains(
          newText.toUpperCase())) {
        SuraResSearch.add(i);
      };
      for (int i = 0; i < QuranResources.arabicQuranSuras.length; i++) {
        if (QuranResources.arabicQuranSuras[i].contains(newText)) {
          SuraResSearch.add(i);
        }
      }
    }
    setState(() {
      filterSearch = SuraResSearch;
    });


  }
}
