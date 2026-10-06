import 'package:flutter/material.dart';
import 'package:islami/di/injection.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/services/quran_download_manager.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/view_model/radio_view_model.dart';
import 'package:provider/provider.dart';

/// App-wide providers, available to every screen and named route.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared singleton services (owned by get_it, so `.value` is used
        // and Provider never disposes them).
        ChangeNotifierProvider.value(value: getIt<ConnectivityMonitor>()),
        ChangeNotifierProvider.value(value: getIt<QuranDownloadManager>()),
        ChangeNotifierProvider.value(value: getIt<AudioPlayerService>()),

        // App-wide so the mini player can control audio from any tab.
        // Lazy: created the first time the Radio / Downloads tab reads them.
        ChangeNotifierProvider(create: (_) => getIt<RadioViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<DownloadsViewModel>()),
      ],
      child: child,
    );
  }
}
