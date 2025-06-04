import 'package:flutter/material.dart';

class CustomEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final String customEllipsis;

  const CustomEllipsisText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
    this.customEllipsis = '...',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final mediaQueryData = MediaQuery.of(context);
      final scale = mediaQueryData.textScaler.clamp(
        minScaleFactor: 1,
        maxScaleFactor: 1,
      );
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      );

      /// Calculate the width of the text
      textPainter.layout(maxWidth: constraints.maxWidth);

      /// If the text exceeds the maximum number of lines, truncate it
      if (textPainter.didExceedMaxLines) {
        final truncatedText = _calculateTruncatedText(
          text,
          constraints.maxWidth,
          style,
          ellipsis: customEllipsis,
        );

        return Text(
          truncatedText,
          style: style,
          textScaler: scale,
          maxLines: maxLines,
        );
      }

      return Text(
        text,
        style: style,
        textScaler: scale,
        maxLines: maxLines,
      );
    });
  }

  String _calculateTruncatedText(
    String text,
    double maxWidth,
    TextStyle style, {
    String ellipsis = '...',
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: ellipsis,
    );

    /// Get the width of the text
    textPainter.layout(maxWidth: double.infinity);

    /// If the text fits within the maximum width, return it
    if (textPainter.width <= maxWidth) {
      return text;
    }

    /// Variables for binary search
    /// low and high are the cursors for the binary search
    /// best is the best truncation point
    int low = 0;
    int high = text.length;
    int best = 0;

    /// Binary search to find the best truncation point
    while (low <= high) {
      /// Calculate the midpoint or cursor position
      int mid = (low + high) ~/ 2;

      /// Truncate the text at the cursor position
      String truncated = text.substring(0, mid) + ellipsis;

      /// Calculate the width of the truncated text
      textPainter.text = TextSpan(text: truncated, style: style);
      textPainter.layout(maxWidth: maxWidth);

      /// If the text fits within the maximum width, update the best truncation point
      if (textPainter.width < maxWidth) {
        /// Update the best truncation point
        best = mid;

        /// Move the low cursor to the right
        low = mid + 1;
      } else {
        /// Move the high cursor to the left
        high = mid - 1;
      }
    }

    /// Return the truncated text
    final result = text.substring(0, best - 1) + ellipsis;
    return result;
  }
}
