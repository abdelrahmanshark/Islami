import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Draws a segmented circular ring with the remaining count in the center.
class SegmentedCircularProgress extends StatelessWidget {
  const SegmentedCircularProgress({
    super.key,
    required this.total,
    required this.remaining,
    this.size = 56,
    this.strokeWidth = 5,
  });

  final int total;
  final int remaining;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeRemaining = remaining.clamp(0, safeTotal);
    final progress = (safeTotal - safeRemaining) / safeTotal;
    // Cap drawn segments so large counts (e.g. 100) still look clean.
    final visualSegments = safeTotal > 12 ? 12 : safeTotal;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SegmentedCircularPainter(
          segmentCount: visualSegments,
          progress: progress,
          strokeWidth: strokeWidth,
          activeColor: AppColors.primaryColor,
          inactiveColor: AppColors.primaryColor.withValues(alpha: 0.25),
        ),
        child: Center(
          child: Text(
            '$safeRemaining',
            style: AppStyles.primaryBold16,
          ),
        ),
      ),
    );
  }
}

class _SegmentedCircularPainter extends CustomPainter {
  _SegmentedCircularPainter({
    required this.segmentCount,
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int segmentCount;
  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Gap between segments so the ring looks segmented.
    const gapRadians = 0.12;
    final sweep = (2 * math.pi / segmentCount) - gapRadians;
    final completedSegments = (progress * segmentCount).round();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < segmentCount; i++) {
      paint.color = i < completedSegments ? activeColor : inactiveColor;
      final startAngle = -math.pi / 2 + (i * (sweep + gapRadians));
      canvas.drawArc(rect, startAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedCircularPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount ||
        oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
