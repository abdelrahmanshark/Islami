import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_pillar_card.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Pillars list for اركان الاسلام, with Arabic search.
class SharawyPillarsView extends StatelessWidget {
  final RadioViewModel provider;

  const SharawyPillarsView({super.key, required this.provider});

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
                    provider.closeSharawyCategory();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    provider.selectedSharawyCategory?.titleAr ?? '',
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
              provider.filterSharawyPillar(newText);
            },
            hintText: 'بحث عن ركن',
            textDirection: TextDirection.rtl,
          ),
          Expanded(
            child: provider.filteredSharawyPillars.isEmpty
                ? Center(
                    child: Text(
                      'عذراً، لم نتمكن من العثور على الركن',
                      style: AppStyles.whiteBold20,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      final pillar = provider.filteredSharawyPillars[index];
                      return SharawyPillarCard(
                        pillar: pillar,
                        onTap: () {
                          provider.openSharawyPillar(pillar);
                        },
                      );
                    },
                    itemCount: provider.filteredSharawyPillars.length,
                  ),
          ),
        ],
      ),
    );
  }
}
