import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';

/// Draws a rotating compass with a Qibla needle in the center.
class QiblaCompass extends StatelessWidget {
  final double compassRadians;
  final double needleRadians;
  final bool isFacingQibla;

  const QiblaCompass({
    super.key,
    required this.compassRadians,
    required this.needleRadians,
    required this.isFacingQibla,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating compass dial
          Transform.rotate(
            angle: compassRadians,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: _CompassDialPainter(),
            ),
          ),
          // Qibla needle
          Transform.rotate(
            angle: needleRadians,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: _QiblaNeedlePainter(
                isFacingQibla: isFacingQibla,
              ),
            ),
          ),
          // Center Kaaba marker
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blackColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isFacingQibla
                    ? AppColors.primaryColor
                    : AppColors.whiteColor,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.mosque,
              color: isFacingQibla
                  ? AppColors.primaryColor
                  : AppColors.whiteColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the outer compass ring and cardinal labels.
class _CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = AppColors.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final tickPaint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 4, ringPaint);

    // Tick marks around the dial
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final isMajor = i % 3 == 0;
      final outer = radius - 10;
      final inner = radius - (isMajor ? 28 : 18);

      final start = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final end = Offset(
        center.dx + outer * math.sin(angle),
        center.dy - outer * math.cos(angle),
      );

      tickPaint.strokeWidth = isMajor ? 2.5 : 1.5;
      tickPaint.color = isMajor
          ? AppColors.primaryColor
          : AppColors.primaryColor.withValues(alpha: 0.5);
      canvas.drawLine(start, end, tickPaint);
    }

    // Cardinal direction labels (N toward top of dial)
    _drawLabel(canvas, center, radius, 'ش', 0);
    _drawLabel(canvas, center, radius, 'ق', 90);
    _drawLabel(canvas, center, radius, 'ج', 180);
    _drawLabel(canvas, center, radius, 'غ', 270);
  }

  /// Draws a single cardinal letter on the dial.
  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String text,
    double degrees,
  ) {
    final angle = degrees * math.pi / 180;
    final offset = Offset(
      center.dx + (radius - 48) * math.sin(angle),
      center.dy - (radius - 48) * math.cos(angle),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the Qibla needle pointing toward Mecca.
class _QiblaNeedlePainter extends CustomPainter {
  final bool isFacingQibla;

  _QiblaNeedlePainter({required this.isFacingQibla});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color =
        isFacingQibla ? AppColors.primaryColor : AppColors.whiteColor;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Needle tip pointing up (toward Qibla when rotated)
    final path = Path()
      ..moveTo(center.dx, center.dy - 95)
      ..lineTo(center.dx - 12, center.dy)
      ..lineTo(center.dx + 12, center.dy)
      ..close();

    canvas.drawPath(path, paint);

    // Tail of the needle
    final tailPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final tail = Path()
      ..moveTo(center.dx, center.dy + 70)
      ..lineTo(center.dx - 8, center.dy)
      ..lineTo(center.dx + 8, center.dy)
      ..close();

    canvas.drawPath(tail, tailPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) {
    return oldDelegate.isFacingQibla != isFacingQibla;
  }
}
