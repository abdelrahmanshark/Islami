import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/utils/app_styles.dart';

/// Bottom bar showing juz/hizb/rub markers and the page number.
class MoshafPageFooter extends StatelessWidget {
  final MoshafPage page;

  const MoshafPageFooter({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4, left: 12, right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              page.pageFooterMarkers,
              textAlign: TextAlign.start,
              style: AppStyles.primaryBold14,
              textDirection: TextDirection.rtl,
            ),
          ),
          Text(
            '${page.pageNumber}',
            style: AppStyles.primaryBold16,
          ),
        ],
      ),
    );
  }
}
