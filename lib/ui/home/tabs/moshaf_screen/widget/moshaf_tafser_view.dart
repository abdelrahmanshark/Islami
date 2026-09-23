import 'package:flutter/material.dart';
import 'package:islami/models/tafser_surah.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Tafsir content panel shown from the Mushaf AppBar icon.
class MoshafTafserView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final String? surahName;
  final TafserAyah? ayah;
  final int? surahNumber;
  final int? ayahNumber;

  const MoshafTafserView({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.surahName,
    this.ayah,
    this.surahNumber,
    this.ayahNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            style: AppStyles.primaryBold16,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    if (ayah == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'اختر آية من المصحف ثم اضغط على تفسير',
            style: AppStyles.primaryBold16,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${surahName ?? 'سورة ${surahNumber ?? ''}'} • آية ${ayahNumber ?? ayah!.ayahNumber}',
          style: AppStyles.primaryBold20,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        Text(
          ayah!.text,
          style: AppStyles.quranAyah,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 24),
        ...ayah!.tafsir.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry.type.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      entry.type,
                      style: AppStyles.primaryBold16,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                Text(
                  entry.text,
                  style: AppStyles.whiteBold16.copyWith(height: 1.8,fontSize: 19),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
