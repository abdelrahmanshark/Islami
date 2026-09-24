import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Shared mini player layout: app name, audio title, and a controls row.
/// Title and controls animate smoothly when the playing audio changes.
class MiniAudioPlayerFrame extends StatelessWidget {
  const MiniAudioPlayerFrame({
    super.key,
    required this.title,
    required this.controls,
    required this.onTap,
  });

  static const Duration _contentDuration = Duration(milliseconds: 300);

  final String title;
  final Widget controls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.blackColor,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text('إسلامي', style: AppStyles.blackBold16),
                  const SizedBox(width: 8),
                  Expanded(
                    // New title slides up and fades in over the old one.
                    child: AnimatedSwitcher(
                      duration: _contentDuration,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      // Same as the default layout, but keeps the title on
                      // the right (start of the Arabic text) instead of center.
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: Text(
                        title,
                        key: ValueKey(title),
                        style: AppStyles.blackBold14,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
              // Cross-fades when the controls type changes (e.g. radio → reciter).
              AnimatedSize(
                duration: _contentDuration,
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: _contentDuration,
                  child: KeyedSubtree(
                    key: ValueKey(controls.runtimeType),
                    child: controls,
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
