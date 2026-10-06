import 'package:flutter/material.dart';
import 'package:islami/utils/app_animations.dart';

/// Shrinks a list card away while [isLeaving], and grows it in when it is
/// first shown with [isEntering] (used when a card moves to/from favorites).
///
/// Give it a key based on the item id, so a moved card is built fresh at its
/// new index and plays the grow animation.
class FavoriteMoveTransition extends StatelessWidget {
  final bool isLeaving;
  final bool isEntering;
  final Widget child;

  const FavoriteMoveTransition({
    super.key,
    required this.isLeaving,
    required this.isEntering,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // `begin` is only used on the first build; later changes of `end`
    // animate from the current value.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: isEntering ? 0 : 1,
        end: isLeaving ? 0 : 1,
      ),
      duration: AppAnimations.listMove,
      curve: AppAnimations.curve,
      builder: (context, value, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: value,
            child: Opacity(opacity: value, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
