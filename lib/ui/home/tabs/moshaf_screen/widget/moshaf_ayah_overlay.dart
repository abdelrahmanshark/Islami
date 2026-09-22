import 'package:flutter/material.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/ayah_highlight_painter.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/ayah_tafser_label.dart';

/// Transparent hit layer on top of a Mushaf page image.
///
/// Scales JSON polygons from the 345×550 coordinate space to the
/// actual displayed image size, highlights the selected ayah, and
/// reports taps to the ViewModel.
class MoshafAyahOverlay extends StatelessWidget {
  final List<AyahCoordinate> ayahs;
  final AyahCoordinate? selectedAyah;
  final AyahCoordinate? Function(Offset localPosition, Size size) findAyahAt;
  final ValueChanged<AyahCoordinate> onAyahTapped;
  final VoidCallback? onTafserLabelTapped;

  const MoshafAyahOverlay({
    super.key,
    required this.ayahs,
    required this.selectedAyah,
    required this.findAyahAt,
    required this.onAyahTapped,
    this.onTafserLabelTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (ayahs.isEmpty) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final scaleX = size.width / MoshafViewModel.coordinatePageWidth;
        final scaleY = size.height / MoshafViewModel.coordinatePageHeight;

        return Stack(
          children: [
            // Must be Positioned.fill so the hit layer keeps full size
            // (Stack gives loose constraints to non-positioned children).
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final tapped = findAyahAt(details.localPosition, size);
                  if (tapped != null) {
                    onAyahTapped(tapped);
                  }
                },
                child: CustomPaint(
                  painter: selectedAyah == null
                      ? null
                      : AyahHighlightPainter(
                          ayah: selectedAyah!,
                          scaleX: scaleX,
                          scaleY: scaleY,
                        ),
                ),
              ),
            ),
            if (selectedAyah != null && onTafserLabelTapped != null)
              _buildTafserLabel(size, scaleX, scaleY),
          ],
        );
      },
    );
  }

  /// Places the تفسير label near the top of the selected ayah bounds.
  Widget _buildTafserLabel(Size size, double scaleX, double scaleY) {
    final bounds = selectedAyah!.scaledBounds(scaleX, scaleY);
    const labelWidth = 64.0;
    const labelHeight = 32.0;

    // Prefer above the ayah; if too close to the top, place below.
    var top = bounds.top - labelHeight - 4;
    if (top < 0) {
      top = bounds.bottom + 4;
    }

    // Align to the right edge of the ayah (RTL reading side).
    var left = bounds.right - labelWidth;
    if (left < 0) left = 0;
    if (left + labelWidth > size.width) {
      left = size.width - labelWidth;
    }

    return Positioned(
      left: left,
      top: top.clamp(0.0, size.height - labelHeight),
      child: AyahTafserLabel(onTap: onTafserLabelTapped!),
    );
  }
}
