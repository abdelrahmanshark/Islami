import 'package:flutter/material.dart';
import 'package:islami/models/riyad_search_type.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Dropdown at the end of the search field to pick الباب or الحديث.
class RiyadSearchTypeMenu extends StatelessWidget {
  final RiyadSearchType selectedType;
  final ValueChanged<RiyadSearchType> onSelected;

  const RiyadSearchTypeMenu({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<RiyadSearchType>(
      initialValue: selectedType,
      onSelected: onSelected,
      color: AppColors.blackColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.primaryColor),
      ),
      itemBuilder: (context) {
        return RiyadSearchType.values.map((type) {
          return PopupMenuItem<RiyadSearchType>(
            value: type,
            child: Text(
              type.label,
              style: type == selectedType
                  ? AppStyles.primaryBold16
                  : AppStyles.whiteBold16,
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedType.label, style: AppStyles.primaryBold16),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
