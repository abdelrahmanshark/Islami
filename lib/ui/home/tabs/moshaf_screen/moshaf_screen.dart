import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_view.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class MoshafScreen extends StatefulWidget {
  const MoshafScreen({super.key});

  @override
  State<MoshafScreen> createState() => _MoshafScreenState();
}

class _MoshafScreenState extends State<MoshafScreen> {
  late final MoshafViewModel _viewModel;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _viewModel = MoshafViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadMoshaf();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _pageController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Creates the PageController once metadata has finished loading.
  void _onViewModelChanged() {
    if (!mounted || _pageController != null) return;
    if (_viewModel.isLoading || _viewModel.pages.isEmpty) return;

    final initialIndex =
        (_viewModel.initialPage - 1).clamp(0, _viewModel.pages.length - 1);

    setState(() {
      _pageController = PageController(initialPage: initialIndex);
    });

    _viewModel.markPageRestored();
    _viewModel.updateVisiblePage(initialIndex);
  }

  /// Saves the bookmark and shows a short confirmation.
  Future<void> _onBookmarkPressed() async {
    await _viewModel.saveBookmark();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ موضع القراءة عند الصفحة ${_viewModel.visiblePageNumber}',
          textDirection: TextDirection.rtl,
          style: AppStyles.primaryBold24.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.blackColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens the Quran index and jumps to the selected page.
  Future<void> _openIndex() async {
    final selectedPage = await Navigator.pushNamed(
      context,
      AppRoutes.moshafIndexRouteName,
      arguments: _viewModel.pages,
    ) as int?;

    if (!mounted || selectedPage == null) return;
    if (_pageController == null || !_pageController!.hasClients) return;

    final targetIndex =
        (selectedPage - 1).clamp(0, _viewModel.pages.length - 1);
    await _pageController!.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _viewModel.updateVisiblePage(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoshafViewModel>.value(
      value: _viewModel,
      child: Consumer<MoshafViewModel>(
        builder: (context, provider, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: AppColors.blackColor,
              appBar: AppBar(
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                backgroundColor: AppColors.blackColor,
                centerTitle: true,
                title: Text(
                  provider.isLoading ? 'المصحف' : provider.visiblePageTitle,
                  style: AppStyles.primaryBold16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    onPressed: provider.isLoading ? null : provider.toggleTheme,
                    icon: Icon(
                      provider.isDarkTheme
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: AppColors.primaryColor,
                    ),
                    tooltip: provider.isDarkTheme
                        ? 'الوضع الفاتح'
                        : 'الوضع الداكن',
                  ),
                  IconButton(
                    onPressed: provider.isLoading ? null : _openIndex,
                    icon: const Icon(
                      Icons.list_alt,
                      color: AppColors.primaryColor,
                    ),
                    tooltip: 'الفهرس',
                  ),
                  IconButton(
                    onPressed: provider.isLoading ? null : _onBookmarkPressed,
                    icon: Icon(
                      provider.isCurrentPageBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: AppColors.primaryColor,
                    ),
                    tooltip: 'حفظ الصفحة',
                  ),
                ],
              ),
              body: _buildBody(provider),
            ),
          );
        },
      ),
    );
  }

  /// Builds loading, error, or the horizontal Mushaf PageView.
  Widget _buildBody(MoshafViewModel provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Text(
          provider.errorMessage!,
          style: AppStyles.primaryBold16,
          textDirection: TextDirection.rtl,
        ),
      );
    }

    if (_pageController == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: provider.pages.length,
      onPageChanged: provider.updateVisiblePage,
      itemBuilder: (context, index) {
        return MoshafPageView(
          page: provider.pages[index],
          isDarkTheme: provider.isDarkTheme,
        );
      },
    );
  }
}
