import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Shows the Surah Arabic name and Bismillah when appropriate.
class SuraHeader extends StatelessWidget {
  final int suraIndex;

  const SuraHeader({super.key, required this.suraIndex});

  /// At-Tawbah (index 8) has no Bismillah; Al-Fatiha keeps it as ayah 1.
  bool get _shouldShowBismillah => suraIndex != 0 && suraIndex != 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          QuranResources.arabicQuranSuras[suraIndex],
          style: AppStyles.quranBismillah.copyWith(color: AppColors.blackColor),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        if (_shouldShowBismillah) ...[
          const SizedBox(height: 16),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            style: AppStyles.quranBismillah.copyWith(color: AppColors.blackColor),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
