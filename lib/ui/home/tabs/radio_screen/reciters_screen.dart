import 'package:flutter/material.dart';
import 'package:islami/models/active_audio_type.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/services/quran_audio_download_service.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/view_model/reciter_download_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_card.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/reciter_download_actions_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sura_download_row.dart';
import 'package:islami/ui/home/widgets/active_audio_list_view.dart';
import 'package:islami/ui/home/widgets/playback_failure_snackbar.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class RecitersScreen extends StatelessWidget {
  final Reciters reciter;

  const RecitersScreen({
    super.key,
    required this.reciter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.radioBg),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.transparentColor,
          appBar: AppBar(
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            backgroundColor: AppColors.grayColor,
            iconTheme: IconThemeData(color: AppColors.primaryColor),
            title: Text(
              reciter.name ?? '',
              style: AppStyles.primaryBold24,
            ),
            centerTitle: true,
            actions: [
              Consumer<ConnectivityMonitor>(
                builder: (context, monitor, child) {
                  if (monitor.isOnline) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    onPressed: monitor.checkNow,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.primaryColor,
                    ),
                    tooltip: 'تحديث',
                  );
                },
              ),
            ],
          ),
          body: Consumer2<RadioViewModel, ReciterDownloadViewModel>(
            builder: (context, radioVm, downloadVm, child) {
              return Column(
                children: [
                  const SizedBox(height: 12),
                  ReciterCard(reciter: reciter),
                  const SizedBox(height: 12),
                  ReciterDownloadActionsBar(
                    selectedCount: downloadVm.selectedCount,
                    isDownloading: downloadVm.isDownloading,
                    isDownloadAll: downloadVm.isDownloadAll,
                    progressLabel: downloadVm.isDownloading
                        ? 'جاري التحميل ${downloadVm.downloadCompletedCount}/${downloadVm.downloadTotalCount}'
                        : null,
                    onDownloadSelected: () =>
                        _downloadSelected(context, downloadVm),
                    onDownloadAll: () =>
                        _confirmDownloadAll(context, downloadVm),
                    onCancelDownload: downloadVm.isDownloadAll
                        ? downloadVm.cancelCurrentSuraDownload
                        : downloadVm.cancelDownload,
                    onCancelAllDownloads: downloadVm.cancelAllDownloads,
                  ),
                  const SizedBox(height: 12),
                  SuraSearchBar(
                    onChanged: radioVm.onSearch,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  radioVm.filterSearch.isEmpty
                      ? Text(
                          'عذراً، لم نتمكن من العثور على السورة',
                          style: AppStyles.whiteBold20,
                        )
                      : Expanded(
                          child: ActiveAudioListView(
                            activeIndex: radioVm.activeSuraIndexFor(reciter),
                            scrollRequested: radioVm.shouldScrollToActive(
                              ActiveAudioType.reciter,
                            ),
                            onScrollHandled: radioVm.onScrolledToActive,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final int suraIndex =
                                  radioVm.filterSearch[index];
                              final int suraId = suraIndex + 1;
                              final bool isActiveSura =
                                  radioVm.selectedReciterId ==
                                      reciter.id &&
                                  radioVm.currentSura == suraId;
                              final bool isPlaying = isActiveSura &&
                                  radioVm.isReciterPlaying;
                              return SuraDownloadRow(
                                suraIndex: suraIndex,
                                isSelected:
                                    downloadVm.isSuraSelected(suraId),
                                isDownloaded:
                                    downloadVm.isSuraDownloaded(suraId),
                                isActiveSura: isActiveSura,
                                isPlaying: isPlaying,
                                onPlay: () async {
                                  final bool played = isActiveSura
                                      ? await radioVm.playReciter(reciter)
                                      : await radioVm.playReciterSura(
                                          reciter,
                                          suraId,
                                        );
                                  if (!played && context.mounted) {
                                    showPlaybackFailureSnackBar(context);
                                  }
                                },
                                onToggleSelect: (_) {
                                  final bool selected =
                                      downloadVm.toggleSuraSelection(suraId);
                                  if (!selected) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'هذه السورة لديك بالفعل',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              height: 2,
                              width: double.infinity,
                              color: AppColors.whiteColor,
                            ),
                            itemCount: radioVm.filterSearch.length,
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Starts download for the selected surahs and shows a result SnackBar.
  Future<void> _downloadSelected(
    BuildContext context,
    ReciterDownloadViewModel downloadVm,
  ) async {
    // Global manager shows the finish snackbar; only warn when nothing starts.
    final int count = await downloadVm.downloadSelected();
    if (!context.mounted) return;
    if (count == 0 &&
        !downloadVm.wasCancelled &&
        downloadVm.skippedAlreadyDownloadedCount == 0 &&
        downloadVm.unavailableCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تحميل أي سورة')),
      );
    } else if (count == 0 && downloadVm.skippedAlreadyDownloadedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_downloadResultMessage(downloadVm, count))),
      );
    }
  }

  /// Builds the snackbar text after a download batch finishes.
  String _downloadResultMessage(
    ReciterDownloadViewModel downloadVm,
    int count,
  ) {
    if (downloadVm.wasCancelled) {
      return count > 0
          ? 'تم إيقاف التحميل بعد $count سورة'
          : 'تم إيقاف التحميل';
    }

    final int skipped = downloadVm.skippedAlreadyDownloadedCount;
    final int unavailable = downloadVm.unavailableCount;
    final List<String> parts = <String>[];

    if (count > 0) {
      parts.add('تم تحميل $count سورة بنجاح');
    }
    if (skipped > 0) {
      parts.add(
        skipped == 1
            ? 'تم تخطي سورة محمّلة مسبقاً'
            : 'تم تخطي $skipped سور محمّلة مسبقاً',
      );
    }
    if (unavailable > 0) {
      parts.add(
        downloadVm.downloadErrorMessage ??
            AudioUnavailableException.userMessage,
      );
    }

    if (parts.isNotEmpty) {
      return parts.join('\n');
    }

    return 'لم يتم تحميل أي سورة';
  }

  /// Confirms then downloads all missing surahs for this reciter.
  Future<void> _confirmDownloadAll(
    BuildContext context,
    ReciterDownloadViewModel downloadVm,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.blackColor,
          title: Text(
            'تحميل كل السور',
            style: AppStyles.primaryBold20,
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل تريد تحميل جميع سور القرآن لهذا القارئ؟\nقد يستغرق ذلك وقتاً ومساحة تخزين كبيرة.',
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
              child: Text('تأكيد', style: AppStyles.primaryBold16),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('بدء تحميل جميع السور...')),
    );

    final int count = await downloadVm.downloadAllSuras();
    if (!context.mounted) return;
    // Finish snackbar is shown by QuranDownloadManager after navigation too.
    if (count == 0 &&
        !downloadVm.wasCancelled &&
        downloadVm.unavailableCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد سور جديدة للتحميل')),
      );
    }
  }
}
