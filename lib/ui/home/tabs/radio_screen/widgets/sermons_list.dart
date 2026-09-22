import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/quran_screen/widgets/sura_search_bar.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/widgets/sermon_card.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class SermonsList extends StatelessWidget {
  const SermonsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RadioViewModel>(
      builder: (context, provider, child) {
        if (provider.sermonIsLoading) {
          return Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }
        if (provider.sermonFailureMsg.isNotEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                provider.sermonFailureMsg,
                style: AppStyles.primaryBold24,
              ),
            ),
          );
        }
        return Expanded(
          child: Column(
            children: [
              SuraSearchBar(
                onChanged: (newText) {
                  provider.filterSermon(newText);
                },
                hintText: 'بحث عن درس',
                textDirection: TextDirection.rtl,
              ),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return SermonCard(sermon: provider.filteredSermons[index]);
                  },
                  itemCount: provider.filteredSermons.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
