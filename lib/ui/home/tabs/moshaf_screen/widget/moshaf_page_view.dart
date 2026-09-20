import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_footer.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_frame.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// One Mushaf image page wrapped in a decorative frame.
class MoshafPageView extends StatelessWidget {
  final MoshafPage page;
  final bool isDarkTheme;

  const MoshafPageView({
    super.key,
    required this.page,
    this.isDarkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDarkTheme ? AppColors.blackColor : AppColors.offWhite;
    final imagePath = AppAssets.quranPageImage(
      page.pageNumber,
      isDark: isDarkTheme,
    );

    return ColoredBox(
      color: backgroundColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: MoshafPageFrame(
                isDarkTheme: isDarkTheme,
                child: Image.asset(
                  imagePath,
                  key: ValueKey(imagePath),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        'تعذر تحميل الصفحة ${page.pageNumber}',
                        style: AppStyles.primaryBold16,
                        textDirection: TextDirection.rtl,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          MoshafPageFooter(page: page),
        ],
      ),
    );
  }
}
