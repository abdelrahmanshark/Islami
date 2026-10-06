import 'package:flutter/material.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/utils/app_colors.dart';

/// Draws a semi-transparent fill over the selected ayah polygon(s).
class AyahHighlightPainter extends CustomPainter {
  final AyahCoordinate ayah;
  final double scaleX;
  final double scaleY;

  const AyahHighlightPainter({
    required this.ayah,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = ayah.toScaledPath(scaleX, scaleY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AyahHighlightPainter oldDelegate) {
    return oldDelegate.ayah != ayah ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY;
  }
}
