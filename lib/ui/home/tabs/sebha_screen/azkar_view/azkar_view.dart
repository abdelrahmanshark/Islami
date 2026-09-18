import 'package:flutter/material.dart';
import 'package:islami/models/azkar_type.dart';
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
    final azkarType = ModalRoute.of(context)!.settings.arguments as AzkarType;

    return ChangeNotifierProvider(
      create: (context) => AzkarViewModel(azkarType: azkarType),
      child: Consumer<AzkarViewModel>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Scaffold(
              backgroundColor: AppColors.grayColor,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              ),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.grayColor,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              backgroundColor: AppColors.grayColor,
              iconTheme: const IconThemeData(color: AppColors.primaryColor),
              title: Text(
                azkarType.title,
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
                  Text(
                    azkarType.title,
                    style: AppStyles.primaryBold24,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: provider.failureMsg.isNotEmpty
                        ? Center(
                            child: Text(
                              provider.failureMsg,
                              style: AppStyles.primaryBold20,
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.azkarList.length,
                            itemBuilder: (context, index) {
                              return AzkarItemCard(
                                item: provider.azkarList[index],
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
