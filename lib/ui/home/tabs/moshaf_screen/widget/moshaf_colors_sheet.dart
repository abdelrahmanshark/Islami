import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_color_option.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Bottom sheet to choose the page and background colors of the current theme.
class MoshafColorsSheet extends StatelessWidget {
  /// Colors offered for both the page text and the background.
  static const List<Color> colorOptions = [
    AppColors.blackColor,
    AppColors.whiteColor,
    AppColors.offWhite,
    AppColors.cream,
    AppColors.sepia,
    AppColors.mint,
    AppColors.primaryColor,
    AppColors.taupe,
    AppColors.brown,
    AppColors.darkRed,
    AppColors.darkGreen,
    AppColors.navy,
  ];

  const MoshafColorsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MoshafViewModel>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.isDarkTheme
                        ? 'ألوان الوضع الداكن'
                        : 'ألوان الوضع الفاتح',
                    style: AppStyles.primaryBold18,
                  ),
                  const SizedBox(height: 16),
                  Text('لون النص', style: AppStyles.whiteBold16),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in colorOptions)
                        MoshafColorOption(
                          color: color,
                          isSelected: color == provider.pageColor,
                          onTap: () => provider.selectPageColor(color),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('لون الخلفية', style: AppStyles.whiteBold16),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in colorOptions)
                        MoshafColorOption(
                          color: color,
                          isSelected: color == provider.backgroundColor,
                          onTap: () => provider.selectBackgroundColor(color),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: provider.resetColors,
                      child: Text(
                        'استعادة الألوان الافتراضية',
                        style: AppStyles.primaryBold14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
