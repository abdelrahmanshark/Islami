import 'package:flutter/material.dart';

/// Slides the mini player up from the bottom bar (size + fade) when it
/// appears, and back down when it disappears.
///
/// Give each [child] a different key to trigger the animation.
class MiniPlayerAnimatedSwitcher extends StatelessWidget {
  const MiniPlayerAnimatedSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          // 1.0 keeps the bottom edge fixed, so it grows upward.
          axisAlignment: 1.0,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }
}
