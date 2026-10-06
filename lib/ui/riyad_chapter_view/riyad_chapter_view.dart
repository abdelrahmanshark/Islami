import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/hadith_screen/widget/hadith_card.dart';
import 'package:islami/ui/riyad_chapter_view/view_model/riyad_chapter_view_model.dart';
import 'package:islami/ui/widget/screen_background.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class RiyadChapterView extends StatelessWidget {
  const RiyadChapterView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiyadChapterViewModel>();
    final height = MediaQuery.heightOf(context);

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        surfaceTintColor: AppColors.transparentColor,
        elevation: 0,
        backgroundColor: AppColors.blackColor,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
        title: Text('رياض الصالحين', style: AppStyles.primaryBold24),
        centerTitle: true,
      ),
      body: ScreenBackground(
        image: AppAssets.hadithBg,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  provider.chapter.title,
                  style: AppStyles.primaryBold20,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.positionText,
                style: AppStyles.whiteBold16,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CarouselSlider.builder(
                  itemCount: provider.chapter.hadiths.length,
                  options: CarouselOptions(
                    height: height * 0.7,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    initialPage: provider.initialIndex,
                    onPageChanged: (index, reason) =>
                        provider.onPageChanged(index),
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return HadithCard(
                      title: provider.hadithTitle(index),
                      content: provider.chapter.hadiths[index].text,
                      isFavorite: provider.isFavorite(index),
                      onFavoritePressed: () => provider.toggleFavorite(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
