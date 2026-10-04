import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/app_assets.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_styles.dart';

typedef OnChanged = void Function(String newText);

class SuraSearchBar extends StatefulWidget {
  /// Increases each time any search bar is tapped, so lists can scroll to top.
  static final ValueNotifier<int> activationCount = ValueNotifier<int>(0);

  final String? hintText;
  final TextDirection? textDirection;

  /// Optional widget shown at the end of the field (e.g. a menu).
  final Widget? suffixIcon;

  /// Optional SVG icon at the start of the field. Defaults to the Quran icon.
  final String? iconAsset;

  /// Current search text kept by the ViewModel (restored from storage).
  final String text;

  const SuraSearchBar({
    super.key,
    required this.onChanged,
    this.text = '',
    this.hintText,
    this.textDirection,
    this.suffixIcon,
    this.iconAsset,
  });
  final OnChanged onChanged;

  @override
  State<SuraSearchBar> createState() => _SuraSearchBarState();
}

class _SuraSearchBarState extends State<SuraSearchBar> {
  // Needed to show text restored or cleared by the ViewModel;
  // typing is still reported through onChanged.
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  /// Shows the ViewModel text when it changes from outside the field.
  @override
  void didUpdateWidget(covariant SuraSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(
          horizontal: 10
      ),
      child: TextField(
        controller: _controller,
        onTap: () {
          SuraSearchBar.activationCount.value++;
        },
        onChanged: (newText) {
          widget.onChanged(newText);
        },
        textDirection: widget.textDirection ?? TextDirection.ltr,
        style: AppStyles.primaryBold20,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: widget.hintText ?? "اسم السورة",
          hintStyle: AppStyles.whiteBold16,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            gapPadding: 12,
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
          enabled: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            gapPadding: 12,
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            gapPadding: 12,
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
          prefixIcon: SvgPicture.asset(
            widget.iconAsset ?? AppAssets.quranIc,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryColor,
              BlendMode.srcIn,
            ),
            fit: BoxFit.scaleDown,
          ),
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
