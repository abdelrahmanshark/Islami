import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:islami/models/reciters_response.dart';
import 'package:islami/providers/app_providers.dart';
import 'package:islami/services/adhan_alarm_scheduler.dart';
import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/services/download_notification_service.dart';
import 'package:islami/services/quran_download_manager.dart';
import 'package:islami/services/weekly_notification_service.dart';
import 'package:islami/ui/home/tabs/radio_screen/reciters_screen.dart';
import 'package:islami/ui/home/tabs/radio_screen/view_model/reciter_download_view_model.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/azkar_view.dart';
import 'package:islami/ui/home/home_screen.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/moshaf_index_view.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_screen.dart';
import 'package:islami/ui/qibla_view/qibla_view.dart';
import 'package:islami/ui/splash_view/splash_view.dart';
import 'package:islami/ui/widgets/download_progress_banner.dart';
import 'package:islami/utils/app_messenger.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_themes.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash until SplashView is ready so it feels like one screen.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);
  // Keep the screen on while the app is open.
  await WakelockPlus.enable();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'تشغيل الصوت',
    androidNotificationOngoing: true,
  );
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.initialize();
    // Keep the next days of Adhan alarms scheduled even if the Time tab is never opened.
    unawaited(AdhanAlarmScheduler.rescheduleFromSaved());
  }
  await WeeklyNotificationService.initAndSchedule(
    onNotificationResponse: QuranDownloadManager.onNotificationResponse,
    onBackgroundNotificationResponse: downloadNotificationBackground,
  );
  await DownloadNotificationService.init();
  // Receives progress from the download foreground-service isolate.
  FlutterForegroundTask.initCommunicationPort();
  // Ensure the cancel port and task listener exist before any download starts.
  QuranDownloadManager.instance;
  await CallAudioGuard.instance.start();
  runApp(const Islami());
}

class Islami extends StatefulWidget {
  const Islami({super.key});

  @override
  State<Islami> createState() => _IslamiState();
}

class _IslamiState extends State<Islami> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ConnectivityMonitor.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityMonitor.instance.stop();
    super.dispose();
  }

  // Re-enable when returning to the app; allow sleep when leaving.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
      ConnectivityMonitor.instance.checkNow();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: MaterialApp(
          scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splashRouteName,
          routes: {
            AppRoutes.splashRouteName: (context) => const SplashView(),
            AppRoutes.homeRouteName: (context) => HomeScreen(),
            AppRoutes.recitersRouteName: (context) {
              final Reciters reciter =
                  ModalRoute.of(context)!.settings.arguments as Reciters;
              return ChangeNotifierProvider(
                create: (_) => ReciterDownloadViewModel(reciter: reciter),
                child: RecitersScreen(reciter: reciter),
              );
            },
            AppRoutes.azkarRouteName: (context) => const AzkarView(),
            AppRoutes.moshafRouteName: (context) {
              final startPage =
                  ModalRoute.of(context)?.settings.arguments as int?;
              return MoshafScreen(startPage: startPage);
            },
            AppRoutes.moshafIndexRouteName: (context) => const MoshafIndexView(),
            AppRoutes.qiblaRouteName: (context) => const QiblaView(),
          },
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const DownloadProgressBanner(),
              ],
            );
          },
        ),
      ),
    );
  }
}
