import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/azkar_category_card.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// "أذكار وأدعية" tab: search field, favorite categories, then all categories.
class AzkarAndDuaaTab extends StatelessWidget {
  const AzkarAndDuaaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SebhaViewModel>();

    if (provider.isAzkarLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (provider.azkarFailureMsg.isNotEmpty) {
      return Center(
        child: Text(provider.azkarFailureMsg, style: AppStyles.primaryBold20),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuraSearchBar(
          text: provider.searchText,
          onChanged: provider.onSearchChanged,
          hintText: 'ابحث عن الأذكار والأدعية',
          textDirection: TextDirection.rtl,
          iconAsset: AppAssets.sebhaIc,
        ),
        const SizedBox(height: 8),
        Expanded(
          // Slivers let the two lists scroll together as one list,
          // while still building only the visible cards.
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'المفضلة',
                    style: AppStyles.primaryBold20,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              if (provider.filteredFavorites.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      provider.favoriteCategoryTitles.isEmpty
                          ? 'لا توجد أذكار في المفضلة'
                          : 'لا توجد نتائج',
                      style: AppStyles.whiteBold16,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: provider.filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final category = provider.filteredFavorites[index];
                    return AzkarCategoryCard(
                      key: ValueKey(category.title),
                      category: category,
                      isFavorite: true,
                      onTap: () => provider.openCategory(context, category),
                      onFavoritePressed: () =>
                          provider.toggleFavorite(category),
                    );
                  },
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'الأذكار والأدعية',
                    style: AppStyles.primaryBold20,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              if (provider.filteredCategories.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'لا توجد نتائج',
                      style: AppStyles.whiteBold16,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: provider.filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = provider.filteredCategories[index];
                    return AzkarCategoryCard(
                      key: ValueKey(category.title),
                      category: category,
                      isFavorite: provider.isFavorite(category),
                      onTap: () => provider.openCategory(context, category),
                      onFavoritePressed: () =>
                          provider.toggleFavorite(category),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
