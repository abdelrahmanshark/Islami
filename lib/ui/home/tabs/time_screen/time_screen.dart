import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/pray_time.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';

class TimeScreen extends StatelessWidget {
  const TimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimeViewModel(),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.timeBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset(AppAssets.header),
            Consumer<TimeViewModel>(
              builder: (context, provider, child) {
                if (provider.isTimeLoading) {
                  return Expanded(child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,),));
                }
                else if (provider.timeFailureMsg.isNotEmpty) {
                  return Expanded(child: Center(child: Text(
                    provider.timeFailureMsg, style: AppStyles.primaryBold24,)));
                }
                return Center(
                  child: Column(
                    children: [
                      PrayTime(
                        timing: provider.timing, dateInfo: provider.dateInfo,)
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
