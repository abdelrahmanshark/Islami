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
class DownloadsView extends StatelessWidget {
  const DownloadsView({super.key});

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadsViewModel(),
      child: Consumer<DownloadsViewModel>(
        builder: (context, viewModel, child) {
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
                  Image.asset(AppAssets.header),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        DownloadsRescanButton(
                          isLoading: viewModel.isLoading,
                          onPressed: () => _onRescan(context, viewModel),
                        ),
                        Expanded(
                          child: Text(
                            viewModel.selectedReciter == null
                                ? 'التحميلات'
                                : viewModel.selectedReciter!.reciterName,
                            style: AppStyles.primaryBold24,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Keeps the title centered opposite the refresh icon.
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (viewModel.selectedReciter != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: viewModel.clearSelectedReciter,
                        icon: Icon(
                          Icons.arrow_forward,
                          color: AppColors.primaryColor,
                        ),
                        label: Text(
                          'العودة للقراء',
                          style: AppStyles.primaryBold16,
                        ),
                      ),
                    ),
                  SuraSearchBar(
                    onChanged: viewModel.selectedReciter == null
                        ? viewModel.filterReciters
                        : viewModel.filterSuras,
                    hintText: viewModel.selectedReciter == null
                        ? 'بحث عن قارئ'
                        : 'بحث عن سورة',
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: DownloadsTabContent(viewModel: viewModel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
