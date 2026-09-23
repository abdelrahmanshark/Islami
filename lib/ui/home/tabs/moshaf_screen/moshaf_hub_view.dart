import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_hub_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_option_card.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Mushaf tab hub: open Mushaf, index, page search, or saved page.
class MoshafHubView extends StatefulWidget {
  const MoshafHubView({super.key});

  @override
  State<MoshafHubView> createState() => _MoshafHubViewState();
}

class _MoshafHubViewState extends State<MoshafHubView> {
  late final MoshafHubViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MoshafHubViewModel();
    _viewModel.loadSavedPage();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoshafHubViewModel>.value(
      value: _viewModel,
      child: Consumer<MoshafHubViewModel>(
        builder: (context, provider, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.quranBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(AppAssets.header),
                    const SizedBox(height: 8),
                    Text(
                      'المصحف',
                      textAlign: TextAlign.center,
                      style: AppStyles.primaryBold24,
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: provider.isLoadingIndex
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  if (provider.errorMessage != null) ...[
                                    Text(
                                      provider.errorMessage!,
                                      style: AppStyles.primaryBold16,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  MoshafOptionCard(
                                    title: 'فتح المصحف',
                                    subtitle: 'ابدأ قراءة المصحف من البداية',
                                    icon: Icons.menu_book_rounded,
                                    onTap: () => provider.openMoshaf(
                                      context,
                                      startPage: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  MoshafOptionCard(
                                    title: 'الفهرس',
                                    subtitle:
                                        'تصفح السور والأجزاء والأحزاب والأرباع',
                                    icon: Icons.list_alt_rounded,
                                    onTap: () => provider.openIndex(context),
                                  ),
                                  const SizedBox(height: 16),
                                  MoshafOptionCard(
                                    title: 'البحث برقم الصفحة',
                                    subtitle: 'أدخل رقم الصفحة للانتقال إليها',
                                    icon: Icons.find_in_page_rounded,
                                    onTap: () => provider.openByPage(context),
                                  ),
                                  if (provider.hasSavedPage) ...[
                                    const SizedBox(height: 16),
                                    MoshafOptionCard(
                                      title: 'الصفحة المحفوظة',
                                      subtitle:
                                          'الانتقال إلى الصفحة ${provider.savedPage}',
                                      icon: Icons.bookmark_rounded,
                                      onTap: () =>
                                          provider.openSavedPage(context),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
