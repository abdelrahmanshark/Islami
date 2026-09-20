import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// One index row: title on the right, starting page number on the left.
class MoshafIndexItemTile extends StatelessWidget {
  final MoshafIndexItem item;
  final VoidCallback onTap;

  const MoshafIndexItemTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        item.title,
        style: AppStyles.primaryBold16,
        textDirection: TextDirection.rtl,
      ),
      trailing: Text(
        'ص ${item.pageNumber}',
        style: AppStyles.whiteBold14,
        textDirection: TextDirection.rtl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
