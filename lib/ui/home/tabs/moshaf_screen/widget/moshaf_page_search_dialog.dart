import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Dialog to enter a Mushaf page number (1–604) and confirm.
class MoshafPageSearchDialog extends StatefulWidget {
  const MoshafPageSearchDialog({super.key});

  /// Shows the dialog and returns the chosen page, or null if cancelled.
  static Future<int?> show(BuildContext context) {
    return showDialog<int>(
      context: context,
      builder: (_) => const MoshafPageSearchDialog(),
    );
  }

  @override
  State<MoshafPageSearchDialog> createState() => _MoshafPageSearchDialogState();
}

class _MoshafPageSearchDialogState extends State<MoshafPageSearchDialog> {
  static const int _minPage = 1;
  static const int _maxPage = 604;

  String _pageText = '';
  String? _errorText;

  /// Parses and validates the entered page number.
  int? get _parsedPage {
    final page = int.tryParse(_pageText.trim());
    if (page == null) return null;
    if (page < _minPage || page > _maxPage) return null;
    return page;
  }

  /// Updates the typed page text and clears any previous error.
  void _onPageChanged(String value) {
    setState(() {
      _pageText = value;
      _errorText = null;
    });
  }

  /// Confirms and pops with the page number when valid.
  void _onConfirm() {
    final page = _parsedPage;
    if (page == null) {
      setState(() {
        _errorText = 'أدخل رقم صفحة بين $_minPage و $_maxPage';
      });
      return;
    }
    Navigator.pop(context, page);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.blackColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        title: Text(
          'الذهاب إلى صفحة',
          style: AppStyles.primaryBold20,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل رقم الصفحة (1 – 604)',
              style: AppStyles.whiteBold14,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: _onPageChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppStyles.primaryBold20,
              cursorColor: AppColors.primaryColor,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                hintText: 'مثال: 250',
                hintStyle: AppStyles.whiteBold16,
                errorText: _errorText,
                errorStyle: AppStyles.primaryBold14.copyWith(
                  color: Colors.redAccent,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _onConfirm(),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppStyles.whiteBold16,
            ),
          ),
          TextButton(
            onPressed: _onConfirm,
            child: Text(
              'انتقال',
              style: AppStyles.primaryBold16,
            ),
          ),
        ],
      ),
    );
  }
}
