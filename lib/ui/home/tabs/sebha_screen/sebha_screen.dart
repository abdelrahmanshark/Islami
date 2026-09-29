import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/azkar_section.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_beads.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/zikr_progress_dots.dart';
import 'package:islami/ui/widgets/screen_background.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';
import '../../../../utils/app_styles.dart';

class SebhaScreen extends StatefulWidget {
  const SebhaScreen({super.key});

  @override
  State<SebhaScreen> createState() => _SebhaScreenState();
}

class _SebhaScreenState extends State<SebhaScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SebhaViewModel(),
      builder: (context, child) {
        var provider = context.watch<SebhaViewModel>();
        return Scaffold(
          body: ScreenBackground(
            image: AppAssets.sebhaBg,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(AppAssets.header),
                        const SizedBox(height: 16),
                        Image.asset(AppAssets.sebhaTitle, height: 40),
                        const SizedBox(height: 16),
                        SebhaBeads(
                          turns: provider.turns,
                          zikr: provider.azkar[provider.azkarIndex],
                          counter: provider.counter,
                          limit: SebhaViewModel.tasbihLimit,
                          onTap: () {
                            provider.rotate();
                            if (provider.isRoundCompleted) {
                              HapticFeedback.mediumImpact();
                            } else {
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ZikrProgressDots(
                          count: provider.azkar.length,
                          activeIndex: provider.azkarIndex,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'إجمالي التسبيحات: ${provider.totalCount}',
                          style: AppStyles.whiteBold14,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AzkarSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
