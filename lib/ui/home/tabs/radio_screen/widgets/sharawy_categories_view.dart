import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_category_card.dart';
import 'package:islami/utils/app_styles.dart';

/// Categories list with Arabic-normalized search.
class SharawyCategoriesView extends StatelessWidget {
  final RadioViewModel provider;

  const SharawyCategoriesView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.sharawyFailureMsg.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            provider.sharawyFailureMsg,
            style: AppStyles.primaryBold24,
          ),
        ),
      );
    }
    return Expanded(
      child: Column(
        children: [
          SuraSearchBar(
            onChanged: (newText) {
              provider.filterSharawyCategory(newText);
            },
            hintText: 'بحث عن قسم',
            textDirection: TextDirection.rtl,
          ),
          Expanded(
            child: provider.filteredSharawyCategories.isEmpty
                ? Center(
                    child: Text(
                      'عذراً، لم نتمكن من العثور على القسم',
                      style: AppStyles.whiteBold20,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      final category =
                          provider.filteredSharawyCategories[index];
                      return SharawyCategoryCard(
                        category: category,
                        onTap: () {
                          provider.openSharawyCategory(category);
                        },
                      );
                    },
                    itemCount: provider.filteredSharawyCategories.length,
                  ),
          ),
        ],
      ),
    );
  }
}
