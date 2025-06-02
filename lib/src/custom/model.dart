import 'package:flutter/material.dart';

@immutable
class MessageElement {
  const MessageElement({
    required this.text,
    this.type = MessageType.text,
    this.userId,
    this.replyMsg,
    this.textRange,
  });

  /// Variable for text
  final String text;

  /// Variable for message type
  final MessageType type;

  /// Variable for user id
  final String? userId;

  /// Variable for reply message
  final String? replyMsg;

  /// Variable for text range
  final TextRange? textRange;

  @override
  String toString() {
    return 'MessageElement(text: $text, textRange: $textRange)';
  }
}

// ignore: constant_identifier_names
enum MessageType { TO, RE, text }

extension MessageTypeExtension on MessageType {
  bool get isTO => this == MessageType.TO;
  bool get isRE => this == MessageType.RE;
  bool get isText => this == MessageType.text;
}
