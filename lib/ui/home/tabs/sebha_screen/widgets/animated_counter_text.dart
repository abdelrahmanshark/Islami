import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Tasbih number that pops in (scale + fade) every time it changes.
class AnimatedCounterText extends StatelessWidget {
  const AnimatedCounterText({super.key, required this.counter});

  final int counter;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      // The new number grows in with a small bounce, the old one shrinks out.
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.4, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Text(
        '$counter',
        // A new key tells AnimatedSwitcher the number changed.
        key: ValueKey<int>(counter),
        textAlign: TextAlign.center,
        style: AppStyles.whiteBold56.copyWith(
          shadows: [
            Shadow(
              color: AppColors.primaryColor.withValues(alpha: 0.7),
              blurRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
