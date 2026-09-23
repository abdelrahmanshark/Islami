import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:islami/utils/network_utils.dart';

/// Shows an offline (or fetch-failure) message with a refresh action.
class NoInternetRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const NoInternetRetryView({
    super.key,
    this.message = NetworkUtils.noInternetMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: AppStyles.primaryBold24,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(
                Icons.refresh,
                color: AppColors.primaryColor,
                size: 40,
              ),
              tooltip: 'تحديث',
            ),
          ],
        ),
      ),
    );
  }
}
