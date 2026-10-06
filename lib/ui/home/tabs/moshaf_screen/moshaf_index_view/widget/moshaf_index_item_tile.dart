import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_index_item.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// One index row: checkmark, title, and starting page number.
class MoshafIndexItemTile extends StatelessWidget {
  final MoshafIndexItem item;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const MoshafIndexItemTile({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconButton(
        onPressed: onToggleComplete,
        tooltip: isCompleted ? 'إلغاء الحفظ' : 'تم الحفظ',
        icon: Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: isCompleted
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.45),
        ),
      ),
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
