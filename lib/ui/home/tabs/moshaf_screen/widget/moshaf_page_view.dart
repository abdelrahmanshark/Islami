import 'package:flutter/material.dart';
import 'package:islami/models/ayah_coordinate.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_ayah_overlay.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_footer.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_image.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_layout.dart';

/// One Mushaf image page painted with the user's page and background colors.
class MoshafPageView extends StatelessWidget {
  final MoshafPage page;
  final Color pageColor;
  final Color backgroundColor;
  final List<AyahCoordinate> ayahs;
  final AyahCoordinate? selectedAyah;
  final AyahCoordinate? Function(Offset localPosition, Size size) findAyahAt;
  final ValueChanged<AyahCoordinate> onAyahTapped;
  final VoidCallback? onTafserLabelTapped;
  final VoidCallback? onAsbabLabelTapped;
  final bool isFooterVisible;
  final VoidCallback? onPageTapped;

  /// Space around the page image.
  static const EdgeInsets _pageImagePadding = EdgeInsets.only(
    left: 10,
    top: 5,
    right: 10,
    bottom: 5,
  );

  /// Space around the ayah tap/highlight layer, used to align it with the text.
  static const EdgeInsets _ayahOverlayPadding = EdgeInsets.only(
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
  );

  const MoshafPageView({
    super.key,
    required this.page,
    required this.pageColor,
    required this.backgroundColor,
    this.ayahs = const [],
    this.selectedAyah,
    required this.findAyahAt,
    required this.onAyahTapped,
    this.onTafserLabelTapped,
    this.onAsbabLabelTapped,
    this.isFooterVisible = false,
    this.onPageTapped,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      // Catches taps outside the ayah layer (margins, frame, footer).
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPageTapped,
        child: Stack(
          children: [
            // Image and ayah layer share one box so highlights stay aligned.
            Positioned.fill(
              child: MoshafPageLayout(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: _pageImagePadding,
                        child: MoshafPageImage(
                          pageNumber: page.pageNumber,
                          imagePath: page.imagePath,
                          pageColor: pageColor,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: _ayahOverlayPadding,
                        child: MoshafAyahOverlay(
                          ayahs: ayahs,
                          selectedAyah: selectedAyah,
                          findAyahAt: findAyahAt,
                          onAyahTapped: onAyahTapped,
                          onTafserLabelTapped: onTafserLabelTapped,
                          onAsbabLabelTapped: onAsbabLabelTapped,
                          onPageTapped: onPageTapped,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: isFooterVisible ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: isFooterVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: ColoredBox(
                    color: backgroundColor,
                    child: MoshafPageFooter(
                      page: page,
                      textColor: pageColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
