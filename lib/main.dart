import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:islami/services/call_audio_guard.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/services/prayer_time_notification_service.dart';
import 'package:islami/services/weekly_notification_service.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/azkar_view.dart';
import 'package:islami/ui/home/home_screen.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/moshaf_index_view.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_screen.dart';
import 'package:islami/ui/qibla_view/qibla_view.dart';
import 'package:islami/ui/splash_view/splash_view.dart';
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
  }
  await WeeklyNotificationService.initAndSchedule();
  await PrayerTimeNotificationService.init();
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
    return ChangeNotifierProvider.value(
      value: ConnectivityMonitor.instance,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.systemUiOverlayStyle,
        child: MaterialApp(
          scaffoldMessengerKey: AppMessenger.scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splashRouteName,
          routes: {
            AppRoutes.splashRouteName: (context) => const SplashView(),
            AppRoutes.homeRouteName: (context) => HomeScreen(),
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
        ),
      ),
    );
  }
}
