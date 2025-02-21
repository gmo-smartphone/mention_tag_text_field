import 'package:flutter/material.dart';

@immutable
class MentionTagElement {
  final String mentionSymbol;
  final String mention;
  final String? prefixSymbolInput;
  final String? prefixSymbolOutput;
  final String? suffixSymbolInput;
  final String? suffixSymbolOutput;
  final Object? data;
  final Widget? stylingWidget;
  final bool isReply;

  /// For Reply
  final String? replyMsg; 

  const MentionTagElement({
    required this.mentionSymbol,
    required this.mention,
    this.prefixSymbolInput,
    this.prefixSymbolOutput,
    this.suffixSymbolInput,
    this.suffixSymbolOutput,
    this.data,
    this.stylingWidget,
    this.isReply = false,
    this.replyMsg,
  });
}
