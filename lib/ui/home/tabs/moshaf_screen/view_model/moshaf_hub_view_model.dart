import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:islami/data/moshaf/moshaf_local_data_source.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_search_dialog.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/shared_preferences.dart';

/// Handles Mushaf hub menu actions and saved-page state.
@injectable
class MoshafHubViewModel extends ChangeNotifier {
  MoshafHubViewModel(this._moshafLocalDataSource);

  final MoshafLocalDataSource _moshafLocalDataSource;

  int? savedPage;

  /// Page the user was on when they last closed the Mushaf.
  int? lastReadPage;

  bool isLoadingIndex = false;
  String? errorMessage;

  List<HafsAyahMeta>? _ayahs;

  /// True when a bookmarked page exists.
  bool get hasSavedPage => savedPage != null;

  /// True when an auto-saved last read page exists.
  bool get hasLastReadPage => lastReadPage != null;

  /// Loads the saved bookmark page and the last read page (if any).
  Future<void> loadSavedPage() async {
    savedPage = await getMoshafLastPage();
    lastReadPage = await getMoshafLastReadPage();
    notifyListeners();
  }

  /// Opens the full-screen Mushaf at [startPage] (1-based), or page 1.
  Future<void> openMoshaf(
    BuildContext context, {
    int? startPage,
  }) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.moshafRouteName,
      arguments: startPage,
    );
    await loadSavedPage();
  }

  /// Opens the index, then the Mushaf at the selected page.
  Future<void> openIndex(BuildContext context) async {
    isLoadingIndex = true;
    errorMessage = null;
    notifyListeners();

    try {
      final ayahs = await _loadAyahs();
      isLoadingIndex = false;
      notifyListeners();

      if (!context.mounted) return;

      final selectedPage = await Navigator.pushNamed(
        context,
        AppRoutes.moshafIndexRouteName,
        arguments: ayahs,
      ) as int?;

      if (!context.mounted || selectedPage == null) return;
      await openMoshaf(context, startPage: selectedPage);
    } catch (_) {
      errorMessage = 'تعذر فتح الفهرس';
      isLoadingIndex = false;
      notifyListeners();
    }
  }

  /// Opens the Mushaf at the saved bookmark page.
  Future<void> openSavedPage(BuildContext context) async {
    if (savedPage == null) return;
    await openMoshaf(context, startPage: savedPage);
  }

  /// Opens the Mushaf at the last page the user was reading.
  Future<void> openLastReadPage(BuildContext context) async {
    if (lastReadPage == null) return;
    await openMoshaf(context, startPage: lastReadPage);
  }

  /// Asks for a page number, then opens the Mushaf at that page.
  Future<void> openByPage(BuildContext context) async {
    final selectedPage = await MoshafPageSearchDialog.show(context);
    if (!context.mounted || selectedPage == null) return;
    await openMoshaf(context, startPage: selectedPage);
  }

  /// Loads ayah metadata once and caches it.
  Future<List<HafsAyahMeta>> _loadAyahs() async {
    if (_ayahs != null) return _ayahs!;

    _ayahs = await _moshafLocalDataSource.fetchAyahMeta();
    return _ayahs!;
  }
}
