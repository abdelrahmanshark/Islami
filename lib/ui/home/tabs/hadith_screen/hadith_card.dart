import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

import '../../../../models/hadith.dart';

class HadithCard extends StatefulWidget {
  int index;

  HadithCard({super.key, required this.index});

  @override
  State<HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<HadithCard> {
  Hadith hadith = Hadith(title: '', content: '');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadHadithContent(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsGeometry.symmetric(vertical: 50, horizontal: 30),
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.hadithCard),
          fit: BoxFit.fill,
        ),
      ),
      child: hadith.title.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: AppColors.blackColor),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("${hadith.title}", style: AppStyles.blackBold24),
                SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      "${hadith.content}",
                      style: AppStyles.blackBold18,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void loadHadithContent(int index) async {
    String fileContent = await rootBundle.loadString(
      'assets/hadith/h$index.txt',
    );
    hadith.title = fileContent.substring(0, fileContent.indexOf("\n"));
    hadith.content = fileContent.substring(fileContent.indexOf("\n") + 1);
    setState(() {});
  }
}
