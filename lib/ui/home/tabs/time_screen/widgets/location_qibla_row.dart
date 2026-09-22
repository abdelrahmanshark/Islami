import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/qibla_banner.dart';
import 'package:islami/ui/home/tabs/time_screen/widgets/user_location_banner.dart';

/// Location and Qibla buttons shown side by side.
class LocationQiblaRow extends StatelessWidget {
  const LocationQiblaRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: UserLocationBanner(),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: QiblaBanner(),
          ),
        ],
      ),
    );
  }
}
