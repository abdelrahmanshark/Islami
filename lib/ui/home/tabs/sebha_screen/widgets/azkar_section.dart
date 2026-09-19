import 'package:flutter/material.dart';
import 'package:islami/models/azkar_type.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/azkar_card.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Azkar section with Evening and Morning cards.
class AzkarSection extends StatelessWidget {
  const AzkarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SebhaViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أذكار',
            style: AppStyles.whiteBold16,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AzkarCard(
                  title: 'أذكار المساء',
                  imagePath: AppAssets.eveningAzkar,
                  onTap: () => provider.openAzkar(context, AzkarType.evening),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AzkarCard(
                  title: 'أذكار الصباح',
                  imagePath: AppAssets.morningAzkar,
                  onTap: () => provider.openAzkar(context, AzkarType.morning),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
