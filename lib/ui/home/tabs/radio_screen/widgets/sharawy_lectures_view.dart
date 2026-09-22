import 'package:flutter/material.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_lecture_card.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Lectures list for the opened Sha'rawy section, with Arabic search.
class SharawyLecturesView extends StatelessWidget {
  final RadioViewModel provider;

  const SharawyLecturesView({super.key, required this.provider});

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    provider.closeSharawySection();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    provider.selectedSharawySection?.title ?? '',
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
              provider.filterSharawyLecture(newText);
            },
            hintText: 'بحث عن محاضرة',
            textDirection: TextDirection.rtl,
          ),
          Expanded(
            child: provider.filteredSharawyLectures.isEmpty
                ? Center(
                    child: Text(
                      'عذراً، لم نتمكن من العثور على المحاضرة',
                      style: AppStyles.whiteBold20,
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      return SharawyLectureCard(
                        lecture: provider.filteredSharawyLectures[index],
                      );
                    },
                    itemCount: provider.filteredSharawyLectures.length,
                  ),
          ),
        ],
      ),
    );
  }
}
