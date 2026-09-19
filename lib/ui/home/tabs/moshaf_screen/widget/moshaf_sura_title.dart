import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Surah name + optional Bismillah when a Surah starts on the page.
class MoshafSuraTitle extends StatelessWidget {
  final int suraNumber;

  const MoshafSuraTitle({super.key, required this.suraNumber});

  /// Al-Fatiha keeps Bismillah as ayah 1; At-Tawbah has none.
  bool get _shouldShowBismillah => suraNumber != 1 && suraNumber != 9;

  @override
  Widget build(BuildContext context) {
    final name = QuranResources.arabicQuranSuras[suraNumber - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Text(
              'سورة $name',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppStyles.quranBismillah.copyWith(
                color: AppColors.blackColor,
                fontSize: 22,
              ),
            ),
            if (_shouldShowBismillah) ...[
              const SizedBox(height: 8),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppStyles.quranBismillah.copyWith(
                  color: AppColors.blackColor,
                  fontSize: 20,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
