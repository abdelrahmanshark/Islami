import 'package:flutter/animation.dart';

/// Shared animation timings so every screen feels the same.
class AppAnimations {
  /// Press/tap feedback (quick so taps feel instant).
  static const Duration press = Duration(milliseconds: 120);

  /// Switching tabs, sections, and content states.
  static const Duration fast = Duration(milliseconds: 220);

  /// A list card shrinking away or growing in (e.g. moving to favorites).
  static const Duration listMove = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;

  /// How much a tappable card shrinks while pressed.
  static const double pressedScale = 0.97;
}
