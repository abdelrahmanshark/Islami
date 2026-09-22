import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:islami/services/weekly_notification_service.dart';
import 'package:islami/ui/home/tabs/sebha_screen/azkar_view/azkar_view.dart';
import 'package:islami/ui/home/home_screen.dart';
import 'package:islami/ui/home/tabs/moshaf_screen/moshaf_index_view/moshaf_index_view.dart';
import 'package:islami/ui/qibla_view/qibla_view.dart';
import 'package:islami/ui/splash_view/splash_view.dart';
import 'package:islami/utils/app_routes.dart';
import 'package:islami/utils/app_themes.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash until SplashView is ready so it feels like one screen.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'تشغيل الصوت',
    androidNotificationOngoing: true,
  );
  if (defaultTargetPlatform == TargetPlatform.android) {
    await AndroidAlarmManager.initialize();
  }
  await WeeklyNotificationService.initAndSchedule();
  runApp(const Islami());
}

class Islami extends StatelessWidget {
  const Islami({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUiOverlayStyle,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splashRouteName,
        routes: {
          AppRoutes.splashRouteName: (context) => const SplashView(),
          AppRoutes.homeRouteName: (context) => HomeScreen(),
          AppRoutes.azkarRouteName: (context) => const AzkarView(),
          AppRoutes.moshafIndexRouteName: (context) => const MoshafIndexView(),
          AppRoutes.qiblaRouteName: (context) => const QiblaView(),
        },
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
      ),
    );
  }
}
