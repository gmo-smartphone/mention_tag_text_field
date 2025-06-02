import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mention_tag_text_field/src/constants.dart';
import 'package:mention_tag_text_field/src/custom/model.dart';
import 'package:mention_tag_text_field/src/mention_tag_data.dart';
import 'package:mention_tag_text_field/src/mention_tag_decoration.dart';
import 'package:mention_tag_text_field/src/string_extensions.dart';

extension ListUpdate<T> on List<T> {
  List<T> update(int pos, T t) {
    final list = <T>[t];
    replaceRange(pos, pos + 1, list);
    return this;
  }
}

class MentionTagTextEditingController extends TextEditingController {
  MentionTagTextEditingController() {
    addListener(_updateCursorPostion);
  }

  @override
  void dispose() {
    _detectionStream.close();
    removeListener(_updateCursorPostion);
    super.dispose();
  }

  void _updateCursorPostion() {
    _cursorPosition = selection.base.offset;
    if (_indexMentionEnd == null) return;
    if (_cursorPosition - _indexMentionEnd! == 1) {
      onChanged(super.text);
    } else if (_cursorPosition - _indexMentionEnd! != 1) {
      _updateOnMention(null);
    }
  }

  final StreamController<MessageElement> _detectionStream =
      StreamController<MessageElement>.broadcast();

  late int _cursorPosition;
  int? _indexMentionEnd;

  String _temp = '';
  String? _mentionInput;

  final List<MessageElement> _mentions = [];

  void onChanged(String value) async {
    // if (onMention == null) return;
    _indexMentionEnd = null;
    String? mention = _getMention(value);
    _updateOnMention(mention);

    if (value.length < _temp.length) {
      _updateMentions(value);
    }

    _temp = value;
  }

  /// Used to set initial text with mentions in it
  set setText(String newText) {
    text = newText;
  }

  /// Returns text with mentions in it
  String get getText {
    final List<MentionTagElement> tempList = List.from(_mentions);
    return super.text.replaceAllMapped(Constants.mentionEscape, (match) {
      final MentionTagElement removedMention = tempList.removeAt(0);
      final String mention = mentionTagDecoration.showMentionStartSymbol
          ? removedMention.mention
          : "${removedMention.mentionSymbol}${removedMention.mention}";
      return mention;
    });
  }

  /// Returns text with mentions in it
  String get getTextWithoutSymbols {
    final List<MessageElement> tempList = List.from(_mentions);
    var text = super.text;
    for (var element in tempList) {
      if (element.type == MessageType.TO) {
        final textTO = "[To:${element.userId}]";
        text = text.replaceAll(element.text, textTO);
      } else if (element.type == MessageType.RE) {
        final textRE = "[Reply: to=${element.userId} mid=${element.replyMsg}]";
        text = text.replaceAll(element.text, textRE);
      }
    }

    return text;
  }

  /// The mentions or tags will be removed automatically using backspaces in TextField.
  /// If you encounter a scenario where you need to remove a custom tag or mention on some action, you need to call remove and give it index of the mention or tag in _controller.mentions.
  ///
  /// Note: _controller.mentions is a custom getter, mentions removed from it won't be removed from TextField so you must call _controller.remove to remove mention or tag from both _controller and TextField.
  void remove({required int index}) {
    try {
      _mentions.removeAt(index);
      super.text =
          super.text.removeCharacterAtCount(Constants.mentionEscape, index + 1);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  late MentionTagDecoration mentionTagDecoration;
  void Function(String?)? onMention;

  set initialMentions(List<(String, Object?, Widget?)> value) {
    for (final mentionTuple in value) {
      if (!super.text.contains(mentionTuple.$1)) return;
      super.text =
          super.text.replaceFirst(mentionTuple.$1, Constants.mentionEscape);
      _temp = super.text;

      final mentionSymbol =
          mentionTuple.$1.checkMentionSymbol(mentionTagDecoration.mentionStart);
      if (mentionSymbol.isEmpty) throw 'No mention symbol with initialMention';

      final mention = mentionTagDecoration.showMentionStartSymbol
          ? mentionTuple.$1
          : mentionTuple.$1
              .removeMentionStart(mentionTagDecoration.mentionStart);

      _mentions.add(
        MessageElement(text: mention),
      );
    }
  }

  void test() {
    final _ = _mentionInput!.first;
  }

  void mention({required String text, String? data}) {
    final indexCursor = selection.base.offset < 0 ? 0 : selection.base.offset;
    final elementMention = MessageElement(
      text: text,
      type: MessageType.TO,
      userId: data,
      textRange: TextRange(
        start: indexCursor + 1,
        end: indexCursor + text.length,
      ),
    );

    final textPart = super.text.substring(0, indexCursor < 0 ? 0 : indexCursor);
    final indexPosition = textPart.countChar(Constants.mentionEscape);
    _mentions.insert(indexPosition, elementMention);

    _replaceLastSubstringWithEscaping(
      indexCursor < 0 ? 0 : indexCursor,
      text,
    );
    print('indexCursor: ${_mentions.toString()}');
  }

  void reply({required String text, String? data, String? replyMsg}) {
    final indexCursor = selection.base.offset;
    final reply = MessageElement(
      text: text,
      userId: data,
      replyMsg: replyMsg,
    );

    final textPart = super.text.substring(0, indexCursor < 0 ? 0 : indexCursor);
    final indexPosition = textPart.countChar(Constants.mentionEscape);
    _mentions.insert(indexPosition, reply);

    _replaceLastSubstringWithEscaping(
      indexCursor < 0 ? 0 : indexCursor,
      text,
    );
  }

  void _replaceLastSubstringWithEscaping(int indexCursor, String replacement) {
    try {
      final mentionLength = mentionTagDecoration.mentionBreak.length;
      _replaceLastSubstring(indexCursor, replacement, allowDecrement: false);

      selection = TextSelection.collapsed(
        offset: indexCursor + replacement.length + mentionLength,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _replaceLastSubstring(
    int indexCursor,
    String replacement, {
    bool allowDecrement = true,
  }) {
    // if (super.text.length == 1) {
    //   super.text = !allowDecrement
    //       ? "$replacement${mentionTagDecoration.mentionBreak}"
    //       : "$text$replacement${mentionTagDecoration.mentionBreak}";
    //   _temp = super.text;
    //   return;
    // }

    var indexMentionStart = _getIndexFromMentionStart(indexCursor, super.text);
    indexMentionStart = indexCursor - indexMentionStart;

    super.text = super.text.replaceRange(
          !allowDecrement ? indexMentionStart - 1 : indexMentionStart,
          indexCursor,
          "$replacement${mentionTagDecoration.mentionBreak}",
        );

    _temp = super.text;
  }

  int _getIndexFromMentionStart(int indexCursor, String value) {
    final mentionStartPattern =
        RegExp(mentionTagDecoration.mentionStart.join('|'));
    var indexMentionStart =
        value.substring(0, indexCursor).reversed.indexOf(mentionStartPattern);
    return indexMentionStart;
  }

  bool _isMentionEmbeddedOrDistinct(String value, int indexMentionStart) {
    final indexMentionStartSymbol = indexMentionStart - 1;
    if (indexMentionStartSymbol == 0) return true;
    if (mentionTagDecoration.allowEmbedding) return true;
    if (value[indexMentionStartSymbol - 1] == '\n') return true;
    if (value[indexMentionStartSymbol - 1] == Constants.mentionEscape) {
      return true;
    }
    if (value[indexMentionStartSymbol - 1] == ' ') return true;
    return false;
  }

  String? _getMention(String value) {
    final indexCursor = selection.base.offset;

    final indexMentionFromStart = _getIndexFromMentionStart(indexCursor, value);

    if (mentionTagDecoration.maxWords != null) {
      final indexMentionEnd = value
          .substring(0, indexCursor)
          .reversed
          .indexOfNthSpace(mentionTagDecoration.maxWords!);

      if (indexMentionEnd != -1 && indexMentionEnd < indexMentionFromStart) {
        return null;
      }
    }

    if (indexMentionFromStart != -1) {
      final indexMentionStart = indexCursor - indexMentionFromStart;
      _indexMentionEnd = (indexMentionStart + indexMentionFromStart) - 1;

      if (value.length == 1) return value.first;

      if (!_isMentionEmbeddedOrDistinct(value, indexMentionStart)) return null;

      if (indexMentionStart != -1 &&
          indexMentionStart >= 0 &&
          indexMentionStart <= indexCursor) {
        return value.substring(indexMentionStart - 1, indexCursor);
      }
    }
    return null;
  }

  void _updateOnMention(String? mention) {
    _mentionInput = mention;
  }

  void _checkAndUpdateOnMention(
    String value,
    int mentionsCountTillCursor,
    int indexCursor,
  ) {
    if (_temp.length - value.length != 1) return;
    if (mentionsCountTillCursor < 1) return;

    var indexMentionEscape = value
        .substring(0, indexCursor)
        .reversed
        .indexOf(Constants.mentionEscape);
    indexMentionEscape = indexCursor - indexMentionEscape - 1;
    final isCursorAtMention = (indexCursor - indexMentionEscape) == 1;
    if (isCursorAtMention) {
      final cursorMention = _mentions[mentionsCountTillCursor - 1];
      final mentionText = cursorMention.text;
      _updateOnMention(mentionText);
    }
  }

  void _updateMentions(String value) {
    try {
      final indexCursor = selection.base.offset;
      final beforeItem = _mentions.firstWhereOrNull(
        (e) {
          return (e.textRange?.start ?? 0) >= indexCursor;
        },
      );

      if (beforeItem != null) {}

      final insideItem = _mentions.firstWhereOrNull(
        (e) {
          return (e.textRange?.start ?? 0) <= indexCursor &&
              indexCursor < (e.textRange?.end ?? 1);
        },
      );

      if (insideItem != null) {
        final start = insideItem.textRange?.start ?? 0;
        final end = insideItem.textRange?.end ?? 1;
        final removedMention =
            _mentions.removeAt(_mentions.indexOf(insideItem));
        super.text = super.text.replaceRange(
              start - (start <= 0 ? 0 : 1),
              end - 1,
              '',
            );

        if (mentionTagDecoration.allowDecrement &&
            _temp.length - value.length == 1) {
          String replacementText =
              removedMention.text.substring(0, removedMention.text.length - 1);

          replacementText = replacementText;

          super.text = super
              .text
              .replaceRange(indexCursor, indexCursor, replacementText);

          final offset = mentionTagDecoration.showMentionStartSymbol
              ? indexCursor + removedMention.text.length - 1
              : indexCursor + removedMention.text.length;
          selection = TextSelection.collapsed(offset: offset);
          _updateOnMention(replacementText);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final res = super.text.split('');
    final List<MessageElement> tempList = List.from(_mentions);

    return TextSpan(
      style: style,
      children: res.map((e) {
        // if (e == Constants.mentionEscape) {
        //   final mention = tempList.removeAt(0);

        //   return WidgetSpan(
        //     child: Text(
        //       mention.text,
        //       style: mentionTagDecoration.mentionTextStyle,
        //       maxLines: 1,
        //       overflow: TextOverflow.ellipsis,
        //       strutStyle: StrutStyle(
        //         fontSize: mentionTagDecoration.mentionTextStyle.fontSize,
        //         height: mentionTagDecoration.mentionTextStyle.height,
        //       ),
        //     ),
        //   );
        // }

        return TextSpan(text: e, style: style);
      }).toList(),
    );
  }
}
