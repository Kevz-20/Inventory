import 'package:flutter/material.dart';

/// Scales text down to fit available width (no ellipsis).
///
/// Intended for large numeric/currency strings that should remain fully visible.
class AdaptiveDigitsText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;

  const AdaptiveDigitsText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
  });

  Alignment _alignment() {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: _alignment(),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

