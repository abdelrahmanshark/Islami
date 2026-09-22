import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/ui/home/widgets/sura_bar.dart';
import 'package:islami/utils/app_colors.dart';

/// Row for one downloaded sura under a reciter.
class DownloadedSuraRow extends StatelessWidget {
  const DownloadedSuraRow({
    super.key,
    required this.download,
    required this.isSelected,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
  });

  final DownloadedAudio download;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPlay,
              child: SuraBar(index: download.suraId - 1),
            ),
          ),
          IconButton(
            onPressed: onPlay,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow_rounded,
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.whiteColor,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.primaryColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
