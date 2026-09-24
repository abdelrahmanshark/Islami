import 'package:flutter/material.dart';

/// Scales and fades between button icons when they change
/// (e.g. play ↔ pause), same as the mini player buttons.
///
/// Give [child] a key that changes with it (e.g. `ValueKey(icon)`),
/// otherwise the animation will not run.
class AnimatedIconSwitcher extends StatelessWidget {
  const AnimatedIconSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }
}
