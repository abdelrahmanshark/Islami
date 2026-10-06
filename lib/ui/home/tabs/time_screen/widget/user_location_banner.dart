import 'package:flutter/material.dart';
import 'package:islami/models/location_failure.dart';
import 'package:islami/ui/home/tabs/time_screen/view_model/time_view_model.dart';
import 'package:islami/ui/widget/pressable_scale.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';
import 'package:provider/provider.dart';

/// Shows the saved city/country and refreshes GPS location when tapped.
class UserLocationBanner extends StatelessWidget {
  const UserLocationBanner({super.key});

  /// Refreshes the location and asks the user to enable GPS when it is off.
  Future<void> _onLocationTap(
    BuildContext context,
    TimeViewModel provider,
  ) async {
    final LocationFailureReason? failure =
        await provider.refreshUserLocation();
    if (failure != LocationFailureReason.serviceDisabled || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'قم بتفعيل الموقع حتى نحدث الصلوات',
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        return PressableScale(
          enabled: !provider.isLocationLoading,
          child: GestureDetector(
            onTap: provider.isLocationLoading
                ? null
                : () => _onLocationTap(context, provider),
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
          ),
        );
      },
    );
  }
}
