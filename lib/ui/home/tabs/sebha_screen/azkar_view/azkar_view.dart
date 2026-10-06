import 'package:flutter/material.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/view_model/azkar_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/widget/azkar_item_card.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class AzkarView extends StatelessWidget {
  const AzkarView({super.key});

  @override
  Widget build(BuildContext context) {
    final category =
        ModalRoute.of(context)!.settings.arguments as AzkarCategory;

    return ChangeNotifierProvider(
      create: (context) => AzkarViewModel(category: category),
      child: Consumer<AzkarViewModel>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.grayColor,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              backgroundColor: AppColors.grayColor,
              iconTheme: const IconThemeData(color: AppColors.primaryColor),
              title: Text(
                'أذكار وأدعية',
                style: AppStyles.primaryBold24,
              ),
              centerTitle: true,
            ),
            body: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.detailsBg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      category.title,
                      style: AppStyles.primaryBold24,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: category.items.length,
                      itemBuilder: (context, index) {
                        return AzkarItemCard(
                          item: category.items[index],
                          remaining: provider.remainingCounts[index],
                          onTap: () => provider.onAzkarTapped(index),
                        );
                      },
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
