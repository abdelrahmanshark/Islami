import 'package:flutter/material.dart';
import 'package:islami/models/location_failure.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/location_qibla_row.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/next_prayer_banner.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/pray_time.dart';
import 'package:islami/ui/home/widgets/no_internet_retry_view.dart';
import 'package:islami/ui/home/widgets/offline_refresh_header.dart';
import 'package:islami/ui/widgets/fade_in.dart';
import 'package:islami/ui/widgets/screen_background.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../../utils/app_assets.dart';

class TimeScreen extends StatelessWidget {
  const TimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TimeViewModel(),
      child: ScreenBackground(
        image: AppAssets.timeBg,
        // Rebuilds only when loading/failure changes, not on every
        // countdown tick. The record `(a, b, c)` compares all values.
        child: Selector<TimeViewModel, (bool, String, LocationFailureReason?)>(
          selector: (context, provider) => (
            provider.isTimeLoading,
            provider.timeFailureMsg,
            provider.locationFailure,
          ),
          builder: (context, state, child) {
            final TimeViewModel provider = context.read<TimeViewModel>();

            if (provider.isTimeLoading) {
              return FadeIn(
                key: const ValueKey('loading'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OfflineRefreshHeader(onRefresh: provider.getTimeResponse),
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.locationFailure != null) {
              return FadeIn(
                key: const ValueKey('locationFailure'),
                child: NoInternetRetryView(
                  message: provider.locationFailureMessage,
                  onRefresh: provider.getTimeResponse,
                ),
              );
            }

            if (provider.timeFailureMsg.isNotEmpty) {
              return FadeIn(
                key: const ValueKey('failure'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OfflineRefreshHeader(onRefresh: provider.getTimeResponse),
                    Expanded(
                      child: NoInternetRetryView(
                        message: provider.timeFailureMsg,
                        onRefresh: provider.getTimeResponse,
                      ),
                    ),
                  ],
                ),
              );
            }

            return FadeIn(
              key: const ValueKey('content'),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OfflineRefreshHeader(onRefresh: provider.getTimeResponse),
                    const SizedBox(height: 12),
                    const LocationQiblaRow(),
                    const SizedBox(height: 12),
                    const NextPrayerBanner(),
                    const SizedBox(height: 20),
                    PrayTime(
                      timing: provider.timing,
                      dateInfo: provider.dateInfo,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
