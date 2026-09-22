import 'package:flutter/material.dart';
import 'package:islami/models/downloaded_audio.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/downloads_view/widget/downloaded_reciter_card.dart';
import 'package:islami/ui/downloads_view/widget/downloaded_reciter_player_card.dart';
import 'package:islami/ui/downloads_view/widget/downloaded_sura_row.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Loading / empty / list content for the Downloads tab.
class DownloadsTabContent extends StatelessWidget {
  const DownloadsTabContent({
    super.key,
    required this.viewModel,
  });

  final DownloadsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Text(
          viewModel.errorMessage!,
          style: AppStyles.primaryBold20,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (viewModel.selectedReciter == null) {
      if (viewModel.filteredReciters.isEmpty) {
        return Center(
          child: Text(
            "قم بالتحميل من الراديو ثم القراء",
            style: AppStyles.whiteBold20,
          ),
        );
      }

      return ListView.builder(
        itemCount: viewModel.filteredReciters.length,
        itemBuilder: (context, index) {
          final summary = viewModel.filteredReciters[index];
          return DownloadedReciterCard(
            summary: summary,
            onTap: () => viewModel.selectReciter(summary),
          );
        },
      );
    }

    if (viewModel.filteredSuras.isEmpty) {
      return Center(
        child: Text(
          'لا توجد سور محمّلة لهذا القارئ',
          style: AppStyles.whiteBold20,
        ),
      );
    }

    return Column(
      children: [
        DownloadedReciterPlayerCard(summary: viewModel.selectedReciter!),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _confirmDeleteAll(context),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.primaryColor,
            ),
            label: Text(
              'حذف كل التحميلات',
              style: AppStyles.primaryBold14,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: viewModel.filteredSuras.length,
            itemBuilder: (context, index) {
              final download = viewModel.filteredSuras[index];
              return DownloadedSuraRow(
                download: download,
                isSelected: viewModel.isSelectedDownload(download),
                isPlaying: viewModel.isPlayingDownload(download),
                onPlay: () => _onSuraPlay(viewModel, download),
                onDelete: () => _confirmDeleteSura(context, download),
              );
            },
            separatorBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              height: 2,
              width: double.infinity,
              color: AppColors.whiteColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Plays a sura, or toggles pause if that sura is already selected.
  void _onSuraPlay(
    DownloadsViewModel viewModel,
    DownloadedAudio download,
  ) {
    if (viewModel.isSelectedDownload(download)) {
      viewModel.playSelectedReciter();
    } else {
      viewModel.playDownloadedSura(download);
    }
  }

  /// Asks before deleting one downloaded sura.
  Future<void> _confirmDeleteSura(
    BuildContext context,
    DownloadedAudio download,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.blackColor,
          title: Text(
            'حذف التحميل',
            style: AppStyles.primaryBold20,
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل تريد حذف هذه السورة من التحميلات؟',
            style: AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('إلغاء', style: AppStyles.whiteBold16),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('حذف', style: AppStyles.primaryBold16),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final bool deleted = await viewModel.deleteDownload(download);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted ? 'تم حذف التحميل' : 'تعذر حذف التحميل'),
      ),
    );
  }

  /// Asks before deleting all downloads for the selected reciter.
  Future<void> _confirmDeleteAll(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.blackColor,
          title: Text(
            'حذف كل التحميلات',
            style: AppStyles.primaryBold20,
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل تريد حذف جميع سور هذا القارئ؟',
            style: AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('إلغاء', style: AppStyles.whiteBold16),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('حذف', style: AppStyles.primaryBold16),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final bool deleted = await viewModel.deleteSelectedReciterDownloads();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'تم حذف كل التحميلات' : 'تعذر حذف التحميلات',
        ),
      ),
    );
  }
}
