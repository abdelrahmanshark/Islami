import 'package:flutter/material.dart';
import 'package:islami/utils/app_animations.dart';

/// Quickly fades its child in when it first appears.
///
/// To replay the fade when a section changes, give it a key that
/// changes with the section, e.g. `FadeIn(key: ValueKey(index), ...)`.
class FadeIn extends StatefulWidget {
  const FadeIn({super.key, required this.child});

  final Widget child;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppAnimations.fast,
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppAnimations.curve,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
