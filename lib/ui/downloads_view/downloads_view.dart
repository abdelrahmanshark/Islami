import 'package:flutter/material.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/downloads_view/widget/downloads_rescan_button.dart';
import 'package:islami/ui/downloads_view/widget/downloads_tab_content.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Tab that lists reciters with offline Quran downloads.
class DownloadsView extends StatefulWidget {
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView> {
  @override
  void initState() {
    super.initState();
    // Runs after the first frame because loading notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DownloadsViewModel>().onTabOpened();
    });
  }

  /// Rescans Music/Islami/Quran and shows a short result message.
  Future<void> _onRescan(
    BuildContext context,
    DownloadsViewModel viewModel,
  ) async {
    await viewModel.rescanDownloads();
    if (!context.mounted) return;

    final String message = viewModel.errorMessage != null
        ? viewModel.errorMessage!
        : viewModel.filteredReciters.isEmpty &&
              viewModel.selectedReciter == null
        ? 'لم يتم العثور على تحميلات على الجهاز'
        : 'تم تحديث التحميلات';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsViewModel>(
      builder: (context, viewModel, child) {
        final bool hasSelectedReciter = viewModel.selectedReciter != null;

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.radioBg),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Image.asset(AppAssets.header,height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      DownloadsRescanButton(
                        isLoading: viewModel.isLoading,
                        onPressed: () => _onRescan(context, viewModel),
                      ),
                      Expanded(
                        child: Text(
                          hasSelectedReciter
                              ? viewModel.selectedReciter!.reciterName
                              : 'التحميلات',
                          style: hasSelectedReciter
                              ? AppStyles.primaryBold16
                              : AppStyles.primaryBold24,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasSelectedReciter)
                        TextButton.icon(
                          onPressed: viewModel.clearSelectedReciter,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            Icons.arrow_forward,
                            color: AppColors.primaryColor,
                            size: 18,
                          ),
                          label: Text(
                            'العودة للقراء',
                            style: AppStyles.primaryBold14,
                          ),
                        )
                      else
                        // Keeps the title centered opposite the refresh icon.
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SuraSearchBar(
                  onChanged: hasSelectedReciter
                      ? viewModel.filterSuras
                      : viewModel.filterReciters,
                  hintText: hasSelectedReciter ? 'بحث عن سورة' : 'بحث عن قارئ',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 6),
                Expanded(child: DownloadsTabContent(viewModel: viewModel)),
              ],
            ),
          ),
        );
      },
    );
  }
}
