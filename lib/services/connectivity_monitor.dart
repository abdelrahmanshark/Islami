import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:islami/utils/network_utils.dart';

/// Polls connectivity and notifies listeners when online/offline changes.
class ConnectivityMonitor extends ChangeNotifier with WidgetsBindingObserver {
  ConnectivityMonitor._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final ConnectivityMonitor instance = ConnectivityMonitor._();

  bool isOnline = true;
  Timer? _timer;
  bool _isChecking = false;

  /// Starts periodic checks (safe to call more than once).
  void start() {
    _checkNow();
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkNow(),
    );
  }

  /// Stops polling (e.g. when the app is disposed).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Forces an immediate connectivity check.
  Future<void> checkNow() => _checkNow();

  Future<void> _checkNow() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final bool online = await NetworkUtils.hasInternetConnection();
      if (online != isOnline) {
        isOnline = online;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.dispose();
  }
}
