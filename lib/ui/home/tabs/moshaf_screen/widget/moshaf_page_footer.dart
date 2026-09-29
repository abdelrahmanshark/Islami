import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/utils/app_styles.dart';

/// Bottom bar showing juz/hizb/rub markers and the page number.
///
/// Light mode: black text. Dark mode: primary-color text.
class MoshafPageFooter extends StatelessWidget {
  final MoshafPage page;
  final bool isDarkTheme;

  const MoshafPageFooter({
    super.key,
    required this.page,
    this.isDarkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final markersStyle =
        isDarkTheme ? AppStyles.primaryBold18 : AppStyles.blackBold18;
    final pageNumberStyle =
        isDarkTheme ? AppStyles.primaryBold20 : AppStyles.blackBold20;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2, top: 4, left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              page.pageFooterMarkers,
              textAlign: TextAlign.start,
              style: markersStyle,
              textDirection: TextDirection.rtl,
            ),
          ),
          Text(
            '${page.pageNumber}',
            style: pageNumberStyle,
          ),
        ],
      ),
    );
  }
}
