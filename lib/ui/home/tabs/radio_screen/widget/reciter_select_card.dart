import 'package:flutter/material.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/ui/home/tabs/radio_screen/widget/favorite_icon_button.dart';
import 'package:islami/ui/widget/pressable_scale.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Card used to pick a reciter before opening the sura list.
class ReciterSelectCard extends StatelessWidget {
  final Reciters reciter;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  const ReciterSelectCard({
    super.key,
    required this.reciter,
    required this.onTap,
    required this.isFavorite,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  reciter.name ?? '',
                  style: AppStyles.blackBold16,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FavoriteIconButton(
                  isFavorite: isFavorite,
                  onPressed: onFavoritePressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
