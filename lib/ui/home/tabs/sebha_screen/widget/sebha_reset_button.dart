import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/utils/app_animations.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Button that asks for confirmation, then resets all sebha counters.
class SebhaResetButton extends StatelessWidget {
  const SebhaResetButton({
    super.key,
    required this.isEnabled,
    required this.onReset,
  });

  final bool isEnabled;
  final VoidCallback onReset;

  /// Shows a confirmation dialog and calls [onReset] when the user agrees.
  Future<void> _confirmReset(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.blackColor,
          title: Text(
            'إعادة تعيين العدادات',
            style: AppStyles.primaryBold20,
            textAlign: TextAlign.center,
          ),
          content: Text(
            'هل تريد تصفير جميع عدادات التسبيح؟',
            style: AppStyles.whiteBold14,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('إلغاء', style: AppStyles.whiteBold16),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('تصفير', style: AppStyles.primaryBold16),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    HapticFeedback.mediumImpact();
    onReset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1 : 0.4,
      duration: AppAnimations.fast,
      child: OutlinedButton(
        onPressed: isEnabled ? () => _confirmReset(context) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.blackColor.withValues(alpha: 0.6),
          side: const BorderSide(color: AppColors.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restart_alt,
              color: AppColors.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'إعادة\nتعيين',
              style: AppStyles.primaryBold14,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
