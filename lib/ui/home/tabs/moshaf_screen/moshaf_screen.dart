import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/view_model/moshaf_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_view.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_search_bar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MoshafScreen extends StatefulWidget {
  const MoshafScreen({super.key});

  @override
  State<MoshafScreen> createState() => _MoshafScreenState();
}

class _MoshafScreenState extends State<MoshafScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final MoshafViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MoshafViewModel();
    _viewModel.loadMoshaf();
    _itemPositionsListener.itemPositions.addListener(_onVisibleItemsChanged);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onVisibleItemsChanged);
    _viewModel.dispose();
    super.dispose();
  }

  /// Picks the page closest to the top of the viewport for the AppBar.
  void _onVisibleItemsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || _viewModel.pages.isEmpty) return;

    // Prefer the item whose top is nearest to (or just above) the viewport top.
    ItemPosition? best;
    for (final position in positions) {
      if (best == null ||
          (position.itemLeadingEdge.abs() < best.itemLeadingEdge.abs())) {
        best = position;
      }
    }
    if (best != null) {
      _viewModel.updateVisiblePage(best.index);
    }
  }

  /// Jumps once to the saved page after the list is ready.
  void _restoreScrollIfNeeded() {
    if (_viewModel.didRestoreScroll) return;
    if (_viewModel.pages.isEmpty) return;

    final targetIndex =
        (_viewModel.initialPage - 1).clamp(0, _viewModel.pages.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: targetIndex);
      }
      _viewModel.markScrollRestored();
      _viewModel.updateVisiblePage(targetIndex);
    });
  }

  /// Saves reading position and shows a short confirmation.
  Future<void> _onLongPressSave(int pageNumber) async {
    await _viewModel.saveReadingPosition(pageNumber: pageNumber);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ موضع القراءة عند الصفحة $pageNumber',
          textDirection: TextDirection.rtl,
          style: AppStyles.primaryBold24.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.blackColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Scrolls to the page matching the current search query.
  void _onSearchSubmitted(String _) {
    final targetIndex = _viewModel.findTargetPageIndex();
    if (targetIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لم يتم العثور على نتيجة',
            textDirection: TextDirection.rtl,
            style: AppStyles.primaryBold16,
          ),
          backgroundColor: AppColors.blackColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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
                  provider.isLoading
                      ? 'المصحف'
                      : provider.visibleSuraName,
                  style: AppStyles.primaryBold20,
                ),
                actions: [
                  IconButton(
                    onPressed: provider.toggleSearch,
                    icon: Icon(
                      provider.isSearchVisible ? Icons.close : Icons.search,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  if (provider.isSearchVisible)
                    MoshafSearchBar(
                      searchMode: provider.searchMode,
                      hintText: provider.searchHint,
                      onChanged: provider.updateSearchQuery,
                      onModeChanged: provider.setSearchMode,
                      onSubmitted: _onSearchSubmitted,
                    ),
                  Expanded(child: _buildBody(provider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds loading, error, or the scrolling Mushaf pages.
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

    _restoreScrollIfNeeded();

    final initialIndex =
        (provider.initialPage - 1).clamp(0, provider.pages.length - 1);

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      initialScrollIndex: initialIndex,
      itemCount: provider.pages.length,
      itemBuilder: (context, index) {
        final page = provider.pages[index];
        return MoshafPageView(
          page: page,
          onLongPress: () => _onLongPressSave(page.pageNumber),
        );
      },
    );
  }
}
