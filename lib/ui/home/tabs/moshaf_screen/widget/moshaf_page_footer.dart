import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/utils/app_styles.dart';

/// Bottom bar showing juz/hizb/rub markers and the page number,
/// written in the same color as the page text.
class MoshafPageFooter extends StatelessWidget {
  final MoshafPage page;
  final Color textColor;

  const MoshafPageFooter({
    super.key,
    required this.page,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
              style: AppStyles.blackBold18.copyWith(color: textColor),
              textDirection: TextDirection.rtl,
            ),
          ),
          Text(
            '${page.pageNumber}',
            style: AppStyles.blackBold20.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
