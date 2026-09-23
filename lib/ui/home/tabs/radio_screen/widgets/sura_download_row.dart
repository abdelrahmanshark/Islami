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
    required this.isActiveSura,
    required this.isPlaying,
    required this.onPlay,
    required this.onToggleSelect,
  });

  /// Zero-based sura index (0–113).
  final int suraIndex;

  final bool isSelected;
  final bool isDownloaded;

  /// Whether this sura is the one currently loaded for playback.
  final bool isActiveSura;

  /// Whether this sura is actively playing (not paused).
  final bool isPlaying;
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
        IconButton(
          onPressed: onPlay,
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow_rounded,
            color: isActiveSura
                ? AppColors.primaryColor
                : AppColors.whiteColor,
            size: 28,
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
