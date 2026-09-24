import 'package:flutter/material.dart';
import 'package:islami/services/audio_player_service.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/services/quran_download_manager.dart';
import 'package:islami/ui/downloads_view/view_model/downloads_view_model.dart';
import 'package:islami/ui/home/tabs/radio_screen/radio_view_model.dart';
import 'package:provider/provider.dart';

/// App-wide providers, available to every screen and named route.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared singleton services.
        ChangeNotifierProvider.value(value: ConnectivityMonitor.instance),
        ChangeNotifierProvider.value(value: QuranDownloadManager.instance),
        ChangeNotifierProvider.value(value: AudioPlayerService.instance),

        // App-wide so the mini player can control audio from any tab.
        // Lazy: created the first time the Radio / Downloads tab reads them.
        ChangeNotifierProvider(create: (_) => RadioViewModel()),
        ChangeNotifierProvider(create: (_) => DownloadsViewModel()),
      ],
      child: child,
    );
  }
}
