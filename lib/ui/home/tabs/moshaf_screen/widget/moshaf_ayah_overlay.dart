import 'package:flutter/material.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/ayah_highlight_painter.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/ayah_option_label.dart';

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

  /// Null when the selected ayah has no asbab, so the option is hidden.
  final VoidCallback? onAsbabLabelTapped;
  final VoidCallback? onPageTapped;

  const MoshafAyahOverlay({
    super.key,
    required this.ayahs,
    required this.selectedAyah,
    required this.findAyahAt,
    required this.onAyahTapped,
    this.onTafserLabelTapped,
    this.onAsbabLabelTapped,
    this.onPageTapped,
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
                onTap: onPageTapped,
                onLongPressStart: (details) {
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
              _buildOptionLabels(size, scaleX, scaleY),
          ],
        );
      },
    );
  }

  /// Places the التفسير / سبب النزول labels near the top of the selected ayah.
  Widget _buildOptionLabels(Size size, double scaleX, double scaleY) {
    final bounds = selectedAyah!.scaledBounds(scaleX, scaleY);
    // Approximate width of the labels row, used to keep it inside the page.
    final labelsWidth = onAsbabLabelTapped == null ? 80.0 : 180.0;
    const labelHeight = 32.0;

    // Prefer above the ayah; if too close to the top, place below.
    var top = bounds.top - labelHeight - 4;
    if (top < 0) {
      top = bounds.bottom + 4;
    }

    // Align to the right edge of the ayah (RTL reading side).
    var right = size.width - bounds.right;
    if (right + labelsWidth > size.width) {
      right = size.width - labelsWidth;
    }
    if (right < 0) right = 0;

    return Positioned(
      right: right,
      top: top.clamp(0.0, size.height - labelHeight),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          AyahOptionLabel(label: 'التفسير', onTap: onTafserLabelTapped!),
          if (onAsbabLabelTapped != null) ...[
            const SizedBox(width: 6),
            AyahOptionLabel(label: 'سبب النزول', onTap: onAsbabLabelTapped!),
          ],
        ],
      ),
    );
  }
}
