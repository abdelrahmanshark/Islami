import 'package:flutter/material.dart';
import 'package:islami/models/riyad_hadith_position.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/favorite_icon_button.dart';
import 'package:islami/ui/widgets/pressable_scale.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Card in the favorites list showing a hadith preview and a heart to remove it.
class RiyadFavoriteHadithCard extends StatelessWidget {
  final RiyadHadithPosition position;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  const RiyadFavoriteHadithCard({
    super.key,
    required this.position,
    required this.onTap,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      '${position.chapter.title} - الحديث ${position.hadithIndex + 1}',
                      style: AppStyles.blackBold14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  FavoriteIconButton(
                    isFavorite: true,
                    onPressed: onFavoritePressed,
                  ),
                ],
              ),
              Text(
                position.hadith.text,
                style: AppStyles.blackBold16,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
