import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_categories_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_lectures_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_pillars_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_sections_view.dart';
import 'package:islami/ui/widgets/fade_in.dart';
import 'package:provider/provider.dart';

/// Sha'rawy tab: categories → (pillars) → sections → lectures.
class SharawyList extends StatelessWidget {
  const SharawyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        String level;
        Widget levelView;
        if (provider.selectedSharawySection != null) {
          level = 'lectures';
          levelView = SharawyLecturesView(provider: provider);
        } else if (provider.selectedSharawyPillar != null) {
          level = 'pillar_sections';
          levelView = SharawySectionsView(provider: provider);
        } else if (provider.selectedSharawyCategory != null) {
          if (provider.isSharawyPillarsCategory) {
            level = 'pillars';
            levelView = SharawyPillarsView(provider: provider);
          } else {
            level = 'sections';
            levelView = SharawySectionsView(provider: provider);
          }
        } else {
          level = 'categories';
          levelView = SharawyCategoriesView(provider: provider);
        }

        // Each level view is an Expanded, so it sits inside a Column.
        return Expanded(
          child: FadeIn(
            key: ValueKey(level),
            child: Column(children: [levelView]),
          ),
        );
      },
    );
  }
}
