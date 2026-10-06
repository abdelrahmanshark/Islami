import 'package:flutter/material.dart';
import 'package:islami/models/asbab_nuzul.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/widget/moshaf_index_tab_button.dart';
import 'package:islami/utils/app_styles.dart';

/// أسباب النزول panel shown in place of the tafsir panel.
class MoshafAsbabView extends StatelessWidget {
  final String surahName;
  final int? ayahNumber;
  final List<AsbabReason> reasons;
  final int selectedSourceIndex;
  final ValueChanged<int> onSourceSelected;

  const MoshafAsbabView({
    super.key,
    required this.surahName,
    required this.ayahNumber,
    required this.reasons,
    required this.selectedSourceIndex,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا يوجد سبب نزول لهذه الآية',
            style: AppStyles.primaryBold16,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    final selectedIndex = selectedSourceIndex.clamp(0, reasons.length - 1);
    final selectedReason = reasons[selectedIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '$surahName • آية ${ayahNumber ?? ''}',
          style: AppStyles.primaryBold20,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 16),
        if (reasons.length > 1)
          Row(
            textDirection: TextDirection.rtl,
            children: [
              for (int i = 0; i < reasons.length; i++)
                MoshafIndexTabButton(
                  label: reasons[i].source,
                  isSelected: i == selectedIndex,
                  onTap: () => onSourceSelected(i),
                ),
            ],
          )
        else
          Text(
            selectedReason.source,
            style: AppStyles.primaryBold16,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        const SizedBox(height: 16),
        Text(
          selectedReason.text,
          style: AppStyles.whiteBold16.copyWith(height: 1.8, fontSize: 19),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}
