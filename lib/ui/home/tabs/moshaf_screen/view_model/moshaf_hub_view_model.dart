import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/widget/moshaf_page_search_dialog.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/shared_preferences.dart';

/// Handles Mushaf hub menu actions and saved-page state.
class MoshafHubViewModel extends ChangeNotifier {
  int? savedPage;
  bool isLoadingIndex = false;
  String? errorMessage;

  List<HafsAyahMeta>? _ayahs;

  /// True when a bookmarked page exists.
  bool get hasSavedPage => savedPage != null;

  /// Loads the saved bookmark page (if any).
  Future<void> loadSavedPage() async {
    savedPage = await getMoshafLastPage();
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

  /// Asks for a page number, then opens the Mushaf at that page.
  Future<void> openByPage(BuildContext context) async {
    final selectedPage = await MoshafPageSearchDialog.show(context);
    if (!context.mounted || selectedPage == null) return;
    await openMoshaf(context, startPage: selectedPage);
  }

  /// Loads ayah metadata once and caches it.
  Future<List<HafsAyahMeta>> _loadAyahs() async {
    if (_ayahs != null) return _ayahs!;

    final jsonString = await rootBundle.loadString(AppAssets.hafsAyahMetaJson);
    final list = jsonDecode(jsonString) as List<dynamic>;
    _ayahs = list
        .map((e) => HafsAyahMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _ayahs!;
  }
}
