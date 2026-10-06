import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';

/// Sizes the Mushaf page content for the current orientation.
///
/// Portrait: [child] fills the available space (unchanged behavior).
/// Landscape: [child] keeps the real page aspect ratio at full width and
/// scrolls vertically, instead of being squashed into the short height.
class MoshafPageLayout extends StatelessWidget {
  final Widget child;

  const MoshafPageLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (!isLandscape) {
          return child;
        }

        final pageWidth = constraints.maxWidth;
        final pageHeight = pageWidth *
            MoshafViewModel.coordinatePageHeight /
            MoshafViewModel.coordinatePageWidth;

        return SingleChildScrollView(
          child: SizedBox(
            width: pageWidth,
            height: pageHeight,
            child: child,
          ),
        );
      },
    );
  }
}
