import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/hadith_screen/hadith_model_view.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class HadithCard extends StatelessWidget {
  int index;

  HadithCard({super.key, required this.index});



  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
      HadithModelView()
        ..loadHadithContent(index),
      child: Consumer<HadithModelView>(
        builder: (BuildContext context, HadithModelView provider,
            Widget? child) {
          return Container(
            padding: EdgeInsetsGeometry.symmetric(vertical: 50, horizontal: 30),
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.hadithCard),
                fit: BoxFit.fill,
              ),
            ),
            child: provider.hadith.title.isEmpty
                ? Center(
              child: CircularProgressIndicator(color: AppColors.blackColor),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("${provider.hadith.title}", style: AppStyles.blackBold24),
                SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      "${provider.hadith.content}",
                      style: AppStyles.blackBold18,
                      textAlign: TextAlign.center,
                    ),
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
