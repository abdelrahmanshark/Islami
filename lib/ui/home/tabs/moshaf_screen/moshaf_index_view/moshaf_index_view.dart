import 'package:flutter/material.dart';
import 'package:islami/models/hafs_ayah_meta.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/view_model/moshaf_index_view_model.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/widget/moshaf_index_item_tile.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/widget/moshaf_index_tab_button.dart';
import 'package:islami/ui/home/widgets/sura_search_bar.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

class MoshafIndexView extends StatefulWidget {
  const MoshafIndexView({super.key});

  @override
  State<MoshafIndexView> createState() => _MoshafIndexViewState();
}

class _MoshafIndexViewState extends State<MoshafIndexView> {
  @override
  void initState() {
    super.initState();
    // Show reminder after the first frame so ScaffoldMessenger is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'قم بالتحديد على ما قرأت/حفظت حتى تتذكره',
            textDirection: TextDirection.rtl,
            style: AppStyles.primaryBold24.copyWith(fontSize: 16),
          ),
          backgroundColor: AppColors.blackColor,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ayahs =
        ModalRoute.of(context)!.settings.arguments as List<HafsAyahMeta>;

    return ChangeNotifierProvider(
      create: (_) => MoshafIndexViewModel(ayahs: ayahs),
      child: Consumer<MoshafIndexViewModel>(
        builder: (context, provider, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: AppColors.blackColor,
              appBar: AppBar(
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                backgroundColor: AppColors.blackColor,
                iconTheme: const IconThemeData(color: AppColors.primaryColor),
                centerTitle: true,
                title: Text(
                  'فهرس المصحف',
                  style: AppStyles.primaryBold20,
                ),
              ),
              body: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        MoshafIndexTabButton(
                          label: 'السور',
                          isSelected: provider.selectedTabIndex == 0,
                          onTap: () => provider.setSelectedTab(0),
                        ),
                        MoshafIndexTabButton(
                          label: 'الأجزاء',
                          isSelected: provider.selectedTabIndex == 1,
                          onTap: () => provider.setSelectedTab(1),
                        ),
                        MoshafIndexTabButton(
                          label: 'الأحزاب',
                          isSelected: provider.selectedTabIndex == 2,
                          onTap: () => provider.setSelectedTab(2),
                        ),
                        MoshafIndexTabButton(
                          label: 'الأرباع',
                          isSelected: provider.selectedTabIndex == 3,
                          onTap: () => provider.setSelectedTab(3),
                        ),
                      ],
                    ),
                  ),
                  if (provider.selectedTabIndex == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SuraSearchBar(
                        onChanged: provider.onSurahSearch,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: provider.currentItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = provider.currentItems[index];
                        return MoshafIndexItemTile(
                          item: item,
                          isCompleted: provider.isItemCompleted(item),
                          onTap: () =>
                              Navigator.pop(context, item.pageNumber),
                          onToggleComplete: () =>
                              provider.toggleItemCompletion(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
