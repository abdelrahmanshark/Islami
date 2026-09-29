import 'package:flutter/material.dart';
import 'package:islami/models/riyad_hadith_position.dart';
import 'package:islami/ui/home/tabs/hadith_screen/widget/riyad_favorite_hadith_card.dart';
import 'package:islami/utils/app_styles.dart';

/// Favorite hadiths list, or a message when there is nothing to show.
class RiyadFavoritesList extends StatelessWidget {
  final List<RiyadHadithPosition> favorites;
  final bool hasSavedFavorites;
  final ValueChanged<RiyadHadithPosition> onFavoriteTap;
  final ValueChanged<RiyadHadithPosition> onFavoritePressed;

  const RiyadFavoritesList({
    super.key,
    required this.favorites,
    required this.hasSavedFavorites,
    required this.onFavoriteTap,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return Center(
        child: Text(
          hasSavedFavorites ? 'لا توجد نتائج' : 'لا توجد أحاديث في المفضلة',
          style: AppStyles.primaryBold20,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final position = favorites[index];
        return RiyadFavoriteHadithCard(
          key: ValueKey(position.hadith.id),
          position: position,
          onTap: () => onFavoriteTap(position),
          onFavoritePressed: () => onFavoritePressed(position),
        );
      },
    );
  }
}
