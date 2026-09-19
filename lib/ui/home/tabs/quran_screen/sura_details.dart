import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/quran_resources.dart';
import 'package:islami/ui/home/tabs/quran_screen/sura_view_model.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/ayahs_paragraph.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_header.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

import '../../../../providers/most_recent_provider.dart';

class SuraDetails extends StatefulWidget {
  const SuraDetails({super.key});

  @override
  State<SuraDetails> createState() => _SuraDetailsState();
}

class _SuraDetailsState extends State<SuraDetails> {
  late MostRecentProvider mostRecentProvider;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  bool _didAutoScroll = false;

  /// Returns (and caches) a GlobalKey for scrolling to a specific ayah.
  GlobalKey _keyForAyah(int ayahIndex) {
    return _ayahKeys.putIfAbsent(ayahIndex, () => GlobalKey());
  }

  /// Scrolls the saved last-read ayah into view.
  void _scrollToLastRead(SuraViewModel provider) {
    if (!provider.hasLastReadInThisSura) return;
    final ayahIndex = provider.lastReadAyahIndex!;
    final key = _ayahKeys[ayahIndex];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  /// Saves last read and shows a short confirmation.
  Future<void> _onSaveLastRead(
    SuraViewModel provider,
    int ayahIndex,
  ) async {
    await provider.saveLastReadAyah(ayahIndex);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ موضع القراءة عند الآية ${ayahIndex + 1}',
          textDirection: TextDirection.rtl,
          style: AppStyles.primaryBold24,
        ),
        backgroundColor: AppColors.blackColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    mostRecentProvider.readMostRecentSuras();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int index = ModalRoute.of(context)!.settings.arguments as int;
    mostRecentProvider = context.watch<MostRecentProvider>();

    return ChangeNotifierProvider(
      create: (context) => SuraViewModel()..loadSuraContent(index),
      child: Consumer<SuraViewModel>(
        builder: (BuildContext context, SuraViewModel provider, Widget? child) {
          if (provider.verses.isEmpty) {
            return Scaffold(
              backgroundColor: AppColors.grayColor,
              body: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          // Auto-scroll once after the last-read ayah is built.
          if (!_didAutoScroll && provider.hasLastReadInThisSura) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _didAutoScroll) return;
              _didAutoScroll = true;
              _scrollToLastRead(provider);
            });
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: AppColors.grayColor,
              appBar: AppBar(
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                backgroundColor: AppColors.grayColor,
                iconTheme: const IconThemeData(color: AppColors.primaryColor),
                title: Text(
                  QuranResources.arabicQuranSuras[index],
                  style: AppStyles.primaryBold20,
                ),
                centerTitle: true,
                actions: [
                  if (provider.hasLastReadInThisSura)
                    TextButton(
                      onPressed: () => _scrollToLastRead(provider),
                      child: Text(
                        'متابعة القراءة',
                        style: AppStyles.primaryBold16,
                      ),
                    ),
                ],
              ),
              body: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SuraHeader(suraIndex: index),
                      AyahsParagraph(
                        verses: provider.verses,
                        isHighlighted: provider.isHighlighted,
                        keyForAyah: _keyForAyah,
                        onLongPress: (ayahIndex) =>
                            _onSaveLastRead(provider, ayahIndex),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
