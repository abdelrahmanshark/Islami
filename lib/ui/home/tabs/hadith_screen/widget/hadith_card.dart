import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/favorite_icon_button.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';

/// Decorated card that shows one hadith title, its text, and a favorite heart.
class HadithCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  const HadithCard({
    super.key,
    required this.title,
    required this.content,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
      margin: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.hadithCard),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppStyles.blackBold24,
            textAlign: TextAlign.center,
          ),
          FavoriteIconButton(
            isFavorite: isFavorite,
            onPressed: onFavoritePressed,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                content,
                style: AppStyles.blackBold18,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
