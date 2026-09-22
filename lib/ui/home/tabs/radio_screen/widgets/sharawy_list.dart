import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_categories_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_lectures_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_pillars_view.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sharawy_sections_view.dart';
import 'package:provider/provider.dart';

/// Sha'rawy tab: categories → (pillars) → sections → lectures.
class SharawyList extends StatelessWidget {
  const SharawyList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        if (provider.selectedSharawySection != null) {
          return SharawyLecturesView(provider: provider);
        }
        if (provider.selectedSharawyPillar != null) {
          return SharawySectionsView(provider: provider);
        }
        if (provider.selectedSharawyCategory != null) {
          if (provider.isSharawyPillarsCategory) {
            return SharawyPillarsView(provider: provider);
          }
          return SharawySectionsView(provider: provider);
        }
        return SharawyCategoriesView(provider: provider);
      },
    );
  }
}
