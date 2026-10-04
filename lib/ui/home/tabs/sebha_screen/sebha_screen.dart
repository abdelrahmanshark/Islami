import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/azkar_and_duaa_tab.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_counter_tab.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/sebha_toggle_switch.dart';
import 'package:islami/ui/widgets/fade_in.dart';
import 'package:islami/ui/widgets/screen_background.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';

class SebhaScreen extends StatelessWidget {
  const SebhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SebhaViewModel(),
      child: Scaffold(
        body: ScreenBackground(
          image: AppAssets.sebhaBg,
          child: Consumer<SebhaViewModel>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                    child: Image.asset(AppAssets.header,height: 80,),
                  ),
                  SebhaToggleSwitch(
                    selectedIndex: provider.tabIndex,
                    onChanged: provider.changeTab,
                  ),
                  Expanded(
                    child: FadeIn(
                      key: ValueKey(provider.tabIndex),
                      child: provider.tabIndex == SebhaViewModel.sebhaTabIndex
                          ? const SebhaCounterTab()
                          : const AzkarAndDuaaTab(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
