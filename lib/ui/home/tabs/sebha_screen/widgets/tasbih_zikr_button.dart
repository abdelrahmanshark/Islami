import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/animated_counter_text.dart';
import 'package:islami/ui/widgets/pressable_scale.dart';
import 'package:islami/utils/app_animations.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Zikr button that fills up from the bottom while its round of 33 is counted.
class TasbihZikrButton extends StatelessWidget {
  const TasbihZikrButton({
    super.key,
    required this.title,
    required this.totalCount,
    required this.progress,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final String title;
  final int totalCount;

  /// Filled part of the button, from 0.0 (empty) to 1.0 (round done).
  final double progress;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  static const Duration fillDuration = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.curve,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.blackColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.35),
              width: isActive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(
                  alpha: isCompleted ? 0.55 : 0,
                ),
                blurRadius: 16,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animates the fill height smoothly whenever [progress] changes.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: progress),
                duration: fillDuration,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    widthFactor: 1,
                    heightFactor: value,
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: AppAnimations.fast,
                      style: isCompleted
                          ? AppStyles.blackBold16
                          : AppStyles.whiteBold16,
                      child: Text(title, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounterText(
                      counter: totalCount,
                      style: isCompleted
                          ? AppStyles.blackBold20
                          : AppStyles.whiteBold20,
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: AnimatedScale(
                  scale: isCompleted ? 1 : 0,
                  duration: fillDuration,
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.blackColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
