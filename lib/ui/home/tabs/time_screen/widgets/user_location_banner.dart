import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Shows the saved city/country and refreshes GPS location when tapped.
class UserLocationBanner extends StatelessWidget {
  const UserLocationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: provider.isLocationLoading
              ? null
              : () => provider.refreshUserLocation(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blackColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryColor, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: provider.isLocationLoading
                      ? const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        )
                      : Text(
                          provider.locationDisplayText,
                          style: AppStyles.primaryBold16,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
