import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/tasbih_zikr.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_beads.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_reset_button.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/tasbih_zikr_button.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:provider/provider.dart';

/// "سبحة" tab: the rotating sebha, the 4 zikr buttons, and the reset button.
class SebhaCounterTab extends StatelessWidget {
  const SebhaCounterTab({super.key});

  static const int gridColumns = 2;
  static const double gridSpacing = 12;
  static const double buttonHeight = 84;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SebhaViewModel>();

    // The reset button stretches to the full height of the zikr grid.
    final int gridRows = (provider.tasbihAzkar.length / gridColumns).ceil();
    final double gridHeight =
        gridRows * buttonHeight + (gridRows - 1) * gridSpacing;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The sebha image has empty space above its ring (for the tassel),
          // so the title is drawn over that space instead of above it.
          Stack(
            fit: StackFit.passthrough,
            children: [
              SebhaBeads(
                turns: provider.turns,
                zikr: provider.activeZikr.title,
                counter: provider.activeZikr.roundCount,
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
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Image.asset(AppAssets.sebhaTitle, height: 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: provider.tasbihAzkar.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumns,
                      mainAxisSpacing: gridSpacing,
                      crossAxisSpacing: gridSpacing,
                      mainAxisExtent: buttonHeight,
                    ),
                    itemBuilder: (context, index) {
                      final TasbihZikr zikr = provider.tasbihAzkar[index];
                      return TasbihZikrButton(
                        title: zikr.title,
                        totalCount: zikr.totalCount,
                        progress: provider.roundProgress(zikr),
                        isActive: index == provider.activeZikrIndex,
                        isCompleted: provider.isZikrCompleted(zikr),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          provider.selectZikr(index);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: gridSpacing),
                SizedBox(
                  width: 64,
                  child: SebhaResetButton(
                    isEnabled: provider.totalCount > 0,
                    onReset: provider.resetAllCounters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
