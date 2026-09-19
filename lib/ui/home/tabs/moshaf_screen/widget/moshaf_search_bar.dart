import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Search field under the AppBar with a mode dropdown (sura / page).
class MoshafSearchBar extends StatelessWidget {
  final MoshafSearchMode searchMode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<MoshafSearchMode> onModeChanged;
  final ValueChanged<String> onSubmitted;

  const MoshafSearchBar({
    super.key,
    required this.searchMode,
    required this.hintText,
    required this.onChanged,
    required this.onModeChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: TextField(
        key: ValueKey(searchMode),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: searchMode == MoshafSearchMode.pageNumber
            ? TextInputType.number
            : TextInputType.text,
        textInputAction: TextInputAction.search,
        textDirection: TextDirection.rtl,
        style: AppStyles.primaryBold16,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppStyles.whiteBold14,
          filled: true,
          fillColor: AppColors.blackColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<MoshafSearchMode>(
                value: searchMode,
                dropdownColor: AppColors.blackColor,
                iconEnabledColor: AppColors.primaryColor,
                style: AppStyles.primaryBold14,
                onChanged: (mode) {
                  if (mode != null) onModeChanged(mode);
                },
                items: const [
                  DropdownMenuItem(
                    value: MoshafSearchMode.suraName,
                    child: Text('اسم السورة'),
                  ),
                  DropdownMenuItem(
                    value: MoshafSearchMode.pageNumber,
                    child: Text('رقم الصفحة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
