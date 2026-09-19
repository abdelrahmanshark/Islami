import 'package:flutter/material.dart';
import 'package:islami/models/azkar_response.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/widget/segmented_circular_progress.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Single azkar row: content text + segmented circular count.
class AzkarItemCard extends StatelessWidget {
  const AzkarItemCard({
    super.key,
    required this.item,
    required this.remaining,
    required this.onTap,
  });

  final AzkarItem item;
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: remaining > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primaryColor),
          color: AppColors.primaryColor,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.content ?? '',
                style: AppStyles.blackBold18,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            SegmentedCircularProgress(
              total: item.countAsInt,
              remaining: remaining,
            ),
          ],
        ),
      ),
    );
  }
}
