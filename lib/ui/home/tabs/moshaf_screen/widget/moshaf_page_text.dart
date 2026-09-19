import 'package:flutter/material.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_sura_title.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Flowing RTL ayah text for one Mushaf page, with Surah headers.
class MoshafPageText extends StatelessWidget {
  final MoshafPage page;

  const MoshafPageText({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final currentSpans = <InlineSpan>[];

    /// Flushes buffered ayah spans into one paragraph widget.
    void flushAyahs() {
      if (currentSpans.isEmpty) return;
      children.add(
        Text.rich(
          TextSpan(children: List<InlineSpan>.from(currentSpans)),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
      currentSpans.clear();
    }

    for (final ayah in page.ayahs) {
      if (ayah.startsSura) {
        flushAyahs();
        children.add(MoshafSuraTitle(suraNumber: ayah.sura));
      }

      currentSpans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: AppStyles.quranAyah.copyWith(color: AppColors.blackColor),
        ),
      );
      currentSpans.add(
        TextSpan(
          text: '﴿${ayah.aya}﴾ ',
          style: AppStyles.quranAyah.copyWith(
            color: AppColors.primaryColor,
            fontSize: 22,
          ),
        ),
      );
    }

    flushAyahs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
