import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_beads.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/zikr_progress_dots.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// "سبحة" tab: the rotating sebha with its counter and progress.
class SebhaCounterTab extends StatelessWidget {
  const SebhaCounterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SebhaViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    );
  }
}
