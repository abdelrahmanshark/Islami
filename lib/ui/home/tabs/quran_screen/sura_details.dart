import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/ui/home/tabs/quran_screen/sura_view_model.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../providers/most_recent_provider.dart';

class SuraDetails extends StatefulWidget {
  SuraDetails({super.key});
  @override
  State<SuraDetails> createState() => _SuraDetailsState();
}

class _SuraDetailsState extends State<SuraDetails> {

  late MostRecentProvider mostRecentProvider;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    mostRecentProvider.readMostRecentSuras();
  }

  @override
  Widget build(BuildContext context) {
    int index = ModalRoute.of(context)!.settings.arguments as int;
    mostRecentProvider = context.watch<MostRecentProvider>();

    return ChangeNotifierProvider(
      create: (context) =>
      SuraViewModel()
        ..loadSuraContent(index),
      child: Consumer<SuraViewModel>(
        builder: (BuildContext context, SuraViewModel provider, Widget? child) {
          return provider.verses.isEmpty
              ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
              : Scaffold(
            backgroundColor: AppColors.grayColor,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              backgroundColor: AppColors.grayColor,
              iconTheme: IconThemeData(color: AppColors.primaryColor),
              title: Text(
                QuranResources.englishQuranSuras[index],
                style: AppStyles.primaryBold24,
              ),
              centerTitle: true,
            ),
            body: Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage(AppAssets.detailsBg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 30),
                  Text(
                    "${QuranResources.arabicQuranSuras[index]}",
                    style: AppStyles.primaryBold24,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index) => Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 40,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.primaryColor),
                        ),
                        child: Text(
                          "${provider.verses[index]} [${index + 1}]",
                          style: AppStyles.primaryBold20,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      itemCount: provider.verses.length,
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
