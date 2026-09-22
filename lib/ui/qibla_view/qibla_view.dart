import 'package:flutter/material.dart';
import 'package:islami/ui/qibla_view/view_model/qibla_view_model.dart';
import 'package:islami/ui/qibla_view/widget/qibla_compass.dart';
import 'package:islami/ui/qibla_view/widget/qibla_info_card.dart';
import 'package:islami/ui/qibla_view/widget/qibla_status_view.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class QiblaView extends StatelessWidget {
  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => QiblaViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.blackColor,
        appBar: AppBar(
          surfaceTintColor: AppColors.transparentColor,
          elevation: 0,
          backgroundColor: AppColors.blackColor,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Text(
            'القبلة',
            style: AppStyles.primaryBold24,
          ),
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.timeBg),
              fit: BoxFit.cover,
            ),
          ),
          child: Consumer<QiblaViewModel>(
            builder: (context, provider, child) {
              if (provider.uiState == QiblaUiState.loading) {
                return const QiblaStatusView(
                  isLoading: true,
                  message: '',
                );
              }

              if (provider.uiState != QiblaUiState.ready) {
                return QiblaStatusView(
                  isLoading: false,
                  message: provider.errorMessage,
                  onRetry: provider.retry,
                );
              }

              return SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'بوصلة القبلة',
                      style: AppStyles.primaryBold20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'وجّه هاتفك أفقيًا بعيدًا عن المعادن',
                      style: AppStyles.whiteBold14,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    QiblaCompass(
                      compassRadians: provider.compassRadians,
                      needleRadians: provider.needleRadians,
                      isFacingQibla: provider.isFacingQibla,
                    ),
                    const Spacer(),
                    QiblaInfoCard(
                      offsetText: provider.offsetText,
                      instructionText: provider.instructionText,
                      isFacingQibla: provider.isFacingQibla,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
