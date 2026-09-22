import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_section_card.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Sections list for an opened Sha'rawy category, with Arabic search.
class SharawySectionsView extends StatelessWidget {
  final RadioViewModel provider;

  const SharawySectionsView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.sharawySectionIsLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Pillars flow goes back to pillars; others go to categories.
                    if (provider.selectedSharawyPillar != null) {
                      provider.closeSharawyPillar();
                    } else {
                      provider.closeSharawyCategory();
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    provider.selectedSharawyPillar?.title ??
                        provider.selectedSharawyCategory?.titleAr ??
                        '',
                    style: AppStyles.primaryBold20,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          SuraSearchBar(
            onChanged: (newText) {
              provider.filterSharawySection(newText);
            },
            hintText: 'بحث عن قسم',
            textDirection: TextDirection.rtl,
          ),
          Expanded(
            child: provider.filteredSharawySections.isEmpty
                ? Center(
                    child: Text(
                      'عذراً، لم نتمكن من العثور على القسم',
                      style: AppStyles.whiteBold20,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      final section =
                          provider.filteredSharawySections[index];
                      return SharawySectionCard(
                        section: section,
                        onTap: () {
                          provider.openSharawySection(section);
                        },
                      );
                    },
                    itemCount: provider.filteredSharawySections.length,
                  ),
          ),
        ],
      ),
    );
  }
}
