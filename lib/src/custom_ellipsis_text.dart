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
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      );

      textPainter.layout(maxWidth: constraints.maxWidth);

      if (textPainter.didExceedMaxLines) {
        // Sử dụng phương thức calculateTruncatedText đã định nghĩa ở trên
        final truncatedText = _calculateTruncatedText(
          text,
          constraints.maxWidth,
          style,
          ellipsis: customEllipsis,
        );

        return Text(
          truncatedText,
          style: style,
          maxLines: maxLines,
        );
      }

      return Text(
        text,
        style: style,
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

    // Kiểm tra xem text có cần cắt không
    textPainter.layout(maxWidth: double.infinity);
    if (textPainter.width <= maxWidth) {
      return text; // Không cần cắt
    }

    // Tính toán số ký tự có thể hiển thị
    int low = 0;
    int high = text.length;
    int best = 0;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      String truncated = text.substring(0, mid) + ellipsis;

      textPainter.text = TextSpan(text: truncated, style: style);
      textPainter.layout(maxWidth: maxWidth);

      if (textPainter.width < maxWidth) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final result = text.substring(0, best - 1) + ellipsis;

    // Trả về text đã cắt với ellipsis
    return result;
  }
}
