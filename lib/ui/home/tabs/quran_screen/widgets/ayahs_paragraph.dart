import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:islami/utils/app_colors.dart';
import 'package:islami/utils/app_styles.dart';

/// Shows all ayahs as one flowing paragraph (side by side), not stacked.
class AyahsParagraph extends StatefulWidget {
  final List<String> verses;
  final bool Function(int ayahIndex) isHighlighted;
  final GlobalKey Function(int ayahIndex) keyForAyah;
  final void Function(int ayahIndex) onLongPress;

  const AyahsParagraph({
    super.key,
    required this.verses,
    required this.isHighlighted,
    required this.keyForAyah,
    required this.onLongPress,
  });

  @override
  State<AyahsParagraph> createState() => _AyahsParagraphState();
}

class _AyahsParagraphState extends State<AyahsParagraph> {
  final List<LongPressGestureRecognizer> _recognizers = [];

  /// Clears old gesture recognizers to avoid leaks.
  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();

    final spans = <InlineSpan>[];
    for (int i = 0; i < widget.verses.length; i++) {
      final ayahIndex = i;
      final recognizer = LongPressGestureRecognizer()
        ..onLongPress = () => widget.onLongPress(ayahIndex);
      _recognizers.add(recognizer);

      final highlighted = widget.isHighlighted(ayahIndex);

      // Invisible anchor so we can scroll to this ayah.
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: SizedBox(
            key: widget.keyForAyah(ayahIndex),
            width: 0,
            height: 0,
          ),
        ),
      );

      final highlightBg = highlighted
          ? AppColors.primaryColor.withValues(alpha: 0.2)
          : null;

      // Ayah text in black.
      spans.add(
        TextSpan(
          text: '${widget.verses[ayahIndex].trim()} ',
          style: AppStyles.quranAyah.copyWith(
            color: AppColors.blackColor,
            backgroundColor: highlightBg,
          ),
          recognizer: recognizer,
        ),
      );

      // Ayah number — larger and primary color.
      spans.add(
        TextSpan(
          text: '﴿${ayahIndex + 1}﴾ ',
          style: AppStyles.quranAyah.copyWith(
            color: AppColors.primaryColor,
            fontSize: 30,
            backgroundColor: highlightBg,
          ),
          recognizer: recognizer,
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
