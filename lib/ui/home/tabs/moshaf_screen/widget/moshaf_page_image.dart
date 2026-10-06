import 'package:flutter/material.dart';
import 'package:islami/utils/app_styles.dart';

/// One Mushaf page image (black text on transparent) painted with [pageColor].
class MoshafPageImage extends StatelessWidget {
  final int pageNumber;
  final String imagePath;
  final Color pageColor;

  const MoshafPageImage({
    super.key,
    required this.pageNumber,
    required this.imagePath,
    required this.pageColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      // srcIn keeps the image shape (its transparency) and fills it with pageColor.
      colorFilter: ColorFilter.mode(pageColor, BlendMode.srcIn),
      child: Image.asset(
        imagePath,
        key: ValueKey(imagePath),
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'تعذر تحميل الصفحة $pageNumber',
              style: AppStyles.primaryBold16,
              textDirection: TextDirection.rtl,
            ),
          );
        },
      ),
    );
  }
}
