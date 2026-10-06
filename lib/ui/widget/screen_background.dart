import 'package:flutter/material.dart';

/// Paints a full-screen background image behind [child].
///
/// The image is sized from the whole screen height (not the available
/// space), so it stays still when the mini audio player shows or hides.
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key, required this.image, required this.child});

  final String image;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight,
          child: Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child,
      ],
    );
  }
}
