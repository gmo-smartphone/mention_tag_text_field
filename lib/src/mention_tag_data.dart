import 'package:flutter/material.dart';

@immutable
class MentionTagElement {
  final String mentionSymbol;
  final String mention;
  final String? prefixSymbol;
  final String? suffixSymbol;
  final Object? data;
  final Widget? stylingWidget;

  const MentionTagElement({
    required this.mentionSymbol,
    required this.mention,
    this.prefixSymbol,
    this.suffixSymbol,
    this.data,
    this.stylingWidget,
  });
}
