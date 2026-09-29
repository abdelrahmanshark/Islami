import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/widget/moshaf_index_tab_button.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';

/// "الكل" / "المفضلة" tabs shown above the radios and reciters lists.
class FavoriteListTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const FavoriteListTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          MoshafIndexTabButton(
            label: 'الكل',
            isSelected: selectedIndex == RadioViewModel.allListTabIndex,
            onTap: () => onChanged(RadioViewModel.allListTabIndex),
          ),
          MoshafIndexTabButton(
            label: 'المفضلة',
            isSelected: selectedIndex == RadioViewModel.favoritesListTabIndex,
            onTap: () => onChanged(RadioViewModel.favoritesListTabIndex),
          ),
        ],
      ),
    );
  }
}
