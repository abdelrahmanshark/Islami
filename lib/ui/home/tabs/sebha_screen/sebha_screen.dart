import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/sebha_screen/sebha_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/widgets/azkar_section.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';
import '../../../../utils/app_styles.dart';

class SebhaScreen extends StatefulWidget {
  const SebhaScreen({super.key});

  @override
  State<SebhaScreen> createState() => _SebhaScreenState();
}

class _SebhaScreenState extends State<SebhaScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SebhaViewModel(),
      builder: (context, child) {
        var provider = context.watch<SebhaViewModel>();
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.sebhaBg),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(AppAssets.header),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () {
                            provider.rotate();
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedRotation(
                                turns: provider.angle / (math.pi),
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeIn,
                                alignment: Alignment.center,
                                child: Image.asset(AppAssets.sebhaBody),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Text(
                                    provider.azkar[provider.azkarIndex],
                                    style: AppStyles.whiteBold20,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "${provider.counter}",
                                    style: AppStyles.whiteBold20,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const AzkarSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
