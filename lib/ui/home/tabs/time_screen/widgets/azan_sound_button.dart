import 'package:flutter/material.dart';
import 'package:islami/ui/home/tabs/time_screen/time_view_model.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:provider/provider.dart';

class AzanSoundButton extends StatelessWidget {
  const AzanSoundButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeViewModel>(
      builder: (context, provider, child) {
        return IconButton(
          onPressed: provider.toggleAzanSound,
          icon: Icon(
            provider.isAzanEnabled ? Icons.volume_up : Icons.volume_off,
            color: AppColors.primaryColor,
          ),
        );
      },
    );
  }
}
