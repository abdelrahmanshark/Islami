import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/animated_counter_text.dart';
import 'package:islami/ui/widgets/pressable_scale.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';

/// Rotating sebha with the current zikr and counter in its center.
class SebhaBeads extends StatelessWidget {
  const SebhaBeads({
    super.key,
    required this.turns,
    required this.zikr,
    required this.counter,
    required this.limit,
    required this.onTap,
  });

  /// Center of the beads ring inside the image (the tassel sits above it),
  /// so the sebha spins around its ring instead of wobbling.
  static const Alignment ringCenter = Alignment(0, 0.17);

  final double turns;
  final String zikr;
  final int counter;
  final int limit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedRotation(
              turns: turns,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              alignment: ringCenter,
              child: Image.asset(AppAssets.sebhaBody),
            ),
            Positioned.fill(
              child: Align(
                alignment: ringCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          zikr,
                          key: ValueKey<String>(zikr),
                          style: AppStyles.whiteBold24,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedCounterText(counter: counter),
                      Text(
                        'من $limit',
                        style: AppStyles.primaryBold16,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
