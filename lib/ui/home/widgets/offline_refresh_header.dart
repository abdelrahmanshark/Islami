import 'package:flutter/material.dart';
import 'package:islami/services/connectivity_monitor.dart';
import 'package:islami/utils/app_assets.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:provider/provider.dart';

/// App header with a refresh icon that only shows while offline.
class OfflineRefreshHeader extends StatelessWidget {
  final VoidCallback? onRefresh;

  const OfflineRefreshHeader({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityMonitor>(
      builder: (context, monitor, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(AppAssets.header),
            if (!monitor.isOnline)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 4,
                left: 8,
                child: IconButton(
                  onPressed: () async {
                    await monitor.checkNow();
                    onRefresh?.call();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: AppColors.primaryColor,
                    size: 32,
                  ),
                  tooltip: 'تحديث',
                ),
              ),
          ],
        );
      },
    );
  }
}
