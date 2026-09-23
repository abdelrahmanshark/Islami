import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/sura_bar.dart';
import 'package:islami/utils/app_colors.dart';

/// Surah row with optional download checkbox and downloaded indicator.
class SuraDownloadRow extends StatelessWidget {
  const SuraDownloadRow({
    super.key,
    required this.suraIndex,
    required this.isSelected,
    required this.isDownloaded,
    required this.onPlay,
    required this.onToggleSelect,
  });

  /// Zero-based sura index (0–113).
  final int suraIndex;

  final bool isSelected;
  final bool isDownloaded;
  final VoidCallback onPlay;
  final ValueChanged<bool?> onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: isSelected,
          // Keep tappable when downloaded so we can show "already have" feedback.
          onChanged: onToggleSelect,
          activeColor: AppColors.primaryColor,
          checkColor: AppColors.blackColor,
          side: const BorderSide(color: AppColors.primaryColor),
        ),
        Expanded(
          child: InkWell(
            onTap: onPlay,
            child: SuraBar(index: suraIndex),
          ),
        ),
        if (isDownloaded)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.download_done,
              color: AppColors.primaryColor,
              size: 22,
            ),
          ),
      ],
    );
  }
}
