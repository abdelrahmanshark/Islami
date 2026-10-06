import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:islami/utils/app_animations.dart';

/// Shrinks its child slightly while a finger is down on it,
/// giving instant tap feedback without delaying the tap itself.
///
/// It only listens to raw pointer events, so the child's own
/// [InkWell] / [GestureDetector] keeps handling the tap as before.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// Set to false when the child is not tappable (e.g. disabled).
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;
  Offset _downPosition = Offset.zero;

  /// Updates the pressed state only when it actually changes.
  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  /// Starts the press animation where the finger touched.
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    _downPosition = event.position;
    _setPressed(true);
  }

  /// Releases the press when the finger moves away (e.g. list scrolling).
  void _onPointerMove(PointerMoveEvent event) {
    final double distance = (event.position - _downPosition).distance;
    if (distance > kTouchSlop) {
      _setPressed(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? AppAnimations.pressedScale : 1,
        duration: AppAnimations.press,
        curve: AppAnimations.curve,
        child: widget.child,
      ),
    );
  }
}
