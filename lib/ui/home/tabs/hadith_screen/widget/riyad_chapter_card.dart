import 'package:flutter/material.dart';
import 'package:islami/models/riyad_assalihin.dart';
import 'package:islami/ui/widgets/pressable_scale.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Chapter card used in the رياض الصالحين chapters list.
class RiyadChapterCard extends StatelessWidget {
  final RiyadChapterModel chapter;
  final VoidCallback onTap;

  const RiyadChapterCard({
    super.key,
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                chapter.title,
                style: AppStyles.blackBold16,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 4),
              Text(
                'عدد الأحاديث: ${chapter.hadiths.length}',
                style: AppStyles.blackBold14,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
