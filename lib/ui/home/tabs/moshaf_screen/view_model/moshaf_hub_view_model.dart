import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/models/moshaf_page.dart';
import 'package:islami/models/moshaf_page_marker.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/shared_preferences.dart';

/// Handles Mushaf hub menu actions and saved-page state.
class MoshafHubViewModel extends ChangeNotifier {
  int? savedPage;
  bool isLoadingIndex = false;
  String? errorMessage;

  List<MoshafPage>? _pages;

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
      final pages = await _loadPages();
      isLoadingIndex = false;
      notifyListeners();

      if (!context.mounted) return;

      final selectedPage = await Navigator.pushNamed(
        context,
        AppRoutes.moshafIndexRouteName,
        arguments: pages,
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

  /// Loads Mushaf page metadata once and caches it.
  Future<List<MoshafPage>> _loadPages() async {
    if (_pages != null) return _pages!;

    final jsonString =
        await rootBundle.loadString(AppAssets.quranWithJuzHizbRubJson);
    final list = jsonDecode(jsonString) as List<dynamic>;
    final markers = list
        .map((e) => MoshafPageMarker.fromJson(e as Map<String, dynamic>))
        .toList();

    _pages = markers.map(MoshafPage.fromMarker).toList();
    return _pages!;
  }
}
