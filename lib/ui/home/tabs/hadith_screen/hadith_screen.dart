import 'package:flutter/material.dart';
import 'package:islami/models/riyad_search_type.dart';
import 'package:islami/ui/home/tabs/hadith_screen/view_model/hadith_view_model.dart';
import 'package:islami/ui/home/tabs/hadith_screen/widget/riyad_chapter_card.dart';
import 'package:islami/ui/home/tabs/hadith_screen/widget/riyad_favorites_list.dart';
import 'package:islami/ui/home/tabs/hadith_screen/widget/riyad_search_type_menu.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/favorite_list_tabs.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/ui/widgets/fade_in.dart';
import 'package:islami/ui/widgets/screen_background.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HadithViewModel(),
      child: ScreenBackground(
        image: AppAssets.hadithBg,
        child: Consumer<HadithViewModel>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(AppAssets.header),
                Text(
                  'رياض الصالحين',
                  style: AppStyles.primaryBold24,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SuraSearchBar(
                  text: provider.searchText,
                  onChanged: provider.onSearchChanged,
                  hintText: provider.searchType.hintText,
                  textDirection: TextDirection.rtl,
                  iconAsset: AppAssets.hadithIc,
                  suffixIcon: RiyadSearchTypeMenu(
                    selectedType: provider.searchType,
                    onSelected: provider.onSearchTypeChanged,
                  ),
                ),
                FavoriteListTabs(
                  selectedIndex: provider.listTabIndex,
                  onChanged: provider.changeListTab,
                ),
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        )
                      : provider.failureMsg.isNotEmpty
                          ? Center(
                              child: Text(
                                provider.failureMsg,
                                style: AppStyles.primaryBold20,
                              ),
                            )
                          : FadeIn(
                              key: ValueKey(provider.listTabIndex),
                              child: provider.isFavoritesTab
                                  ? RiyadFavoritesList(
                                      favorites: provider.filteredFavorites,
                                      hasSavedFavorites: provider
                                          .favoriteHadithIds.isNotEmpty,
                                      onFavoriteTap: (position) => provider
                                          .openFavorite(context, position),
                                      onFavoritePressed: (position) =>
                                          provider.toggleFavoriteHadith(
                                        position.hadith,
                                      ),
                                    )
                                  : provider.filteredChapters.isEmpty
                                      ? Center(
                                          child: Text(
                                            'لا توجد نتائج',
                                            style: AppStyles.primaryBold20,
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          itemCount:
                                              provider.filteredChapters.length,
                                          itemBuilder: (context, index) {
                                            final chapter =
                                                provider.filteredChapters[index];
                                            return RiyadChapterCard(
                                              chapter: chapter,
                                              onTap: () => provider.openChapter(
                                                context,
                                                chapter,
                                              ),
                                            );
                                          },
                                        ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
