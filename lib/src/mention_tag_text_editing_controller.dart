import 'package:flutter/material.dart';
import 'package:mention_tag_text_field/src/constants.dart';
import 'package:mention_tag_text_field/src/mention_ellipsis_text.dart';
import 'package:mention_tag_text_field/src/mention_tag_data.dart';
import 'package:mention_tag_text_field/src/mention_tag_decoration.dart';
import 'package:mention_tag_text_field/src/string_extensions.dart';

class MentionTagTextEditingController extends TextEditingController {
  MentionTagTextEditingController() {
    addListener(_updateCursorPostion);
  }

  @override
  void dispose() {
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

  late int _cursorPosition;
  int? _indexMentionEnd;

  final List<MentionTagElement> _mentions = [];

  /// Get the list of data associated with you mentions, if no data was given the mention labels will be returned.
  List get mentions =>
      List.from(_mentions.map((mention) => mention.data ?? mention.mention));

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
    final List<MentionTagElement> tempList = List.from(_mentions);

    return super.text.replaceAllMapped(Constants.mentionEscape, (match) {
      final element = tempList.removeAt(0);
      final isReply = element.isReply;
      final textForMention =
          "${element.prefixSymbolOutput ?? ''}${element.data}${element.suffixSymbolOutput ?? ''}";
      final textForReply =
          "${element.prefixSymbolOutput ?? ''}to=${element.data} mid=${element.replyMsg}${element.suffixSymbolOutput ?? ''}";
      final String mention = isReply ? textForReply : textForMention;
      return mention;
    });
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
        MentionTagElement(
          mentionSymbol: mentionSymbol,
          mention: mention,
          data: mentionTuple.$2,
          stylingWidget: mentionTuple.$3,
        ),
      );
    }
  }

  String _temp = '';
  String? _mentionInput;

  /// Mention or Tag label, this label will be visible in the Text Field.
  ///
  /// The data associated with this mention. You can get this data using _controller.mentions property.
  /// If you do not pass any data, a list of the mention labels will be returned.
  /// If you skip some values, mentioned labels will be added in those places.
  void addMention({
    required String label,
    Object? data,
    Widget? stylingWidget,
  }) {
    final indexCursor = selection.base.offset;
    final mentionSymbol = _mentionInput!.first;

    final mention = mentionTagDecoration.showMentionStartSymbol
        ? "$mentionSymbol$label"
        : label;
    final MentionTagElement mentionTagElement = MentionTagElement(
      mentionSymbol: mentionSymbol,
      mention: mention,
      data: data,
      stylingWidget: stylingWidget,
    );

    final textPart = super.text.substring(0, indexCursor);
    final indexPosition = textPart.countChar(Constants.mentionEscape);
    _mentions.insert(indexPosition, mentionTagElement);

    _replaceLastSubstringWithEscaping(indexCursor, _mentionInput!);
  }

  void addMentionWithoutSymbol({
    required String name,
    String? prefixSymbolInput,
    String? suffixSymbolInput,
    String? prefixSymbolOutput,
    String? suffixSymbolOutput,
    Object? data,
  }) {
    final indexCursor = selection.base.offset;
    final mentionTagElement = MentionTagElement(
      mentionSymbol: '',
      mention: name,
      prefixSymbolInput: prefixSymbolInput,
      suffixSymbolInput: suffixSymbolInput,
      prefixSymbolOutput: prefixSymbolOutput,
      suffixSymbolOutput: suffixSymbolOutput,
      data: data,
    );

    final fullMention = "$prefixSymbolInput$name$suffixSymbolInput";
    final textPart = super.text.substring(0, indexCursor < 0 ? 0 : indexCursor);
    final indexPosition = textPart.countChar(Constants.mentionEscape);
    _mentions.insert(indexPosition, mentionTagElement);

    _replaceLastSubstringWithEscaping(
      indexCursor < 0 ? 0 : indexCursor,
      fullMention,
    );
  }

  void addReplyWithoutSymbol({
    required String name,
    String? prefixSymbolInput,
    String? suffixSymbolInput,
    String? prefixSymbolOutput,
    String? suffixSymbolOutput,
    Object? data,
    String? replyMsg,
  }) {
    final indexCursor = selection.base.offset;
    final mentionTagElement = MentionTagElement(
      mentionSymbol: '',
      mention: name,
      prefixSymbolInput: prefixSymbolInput,
      suffixSymbolInput: suffixSymbolInput,
      prefixSymbolOutput: prefixSymbolOutput,
      suffixSymbolOutput: suffixSymbolOutput,
      data: data,
      replyMsg: replyMsg,
      isReply: true,
    );

    final fullMention = "$prefixSymbolInput$name$suffixSymbolInput";
    final textPart = super.text.substring(0, indexCursor < 0 ? 0 : indexCursor);
    final indexPosition = textPart.countChar(Constants.mentionEscape);
    _mentions.insert(indexPosition, mentionTagElement);

    _replaceLastSubstringWithEscaping(
      indexCursor < 0 ? 0 : indexCursor,
      fullMention,
    );
  }

  void _replaceLastSubstringWithEscaping(int indexCursor, String replacement) {
    try {
      final mentionLength = mentionTagDecoration.mentionBreak.length;
      _replaceLastSubstring(
        indexCursor,
        Constants.mentionEscape,
        allowDecrement: false,
      );

      selection = TextSelection.collapsed(
        offset: (indexCursor + 1) + mentionLength,
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
    if (super.text.length == 1) {
      super.text = !allowDecrement
          ? "$replacement${mentionTagDecoration.mentionBreak}"
          : "$text$replacement${mentionTagDecoration.mentionBreak}";
      _temp = super.text;
      return;
    }

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
    onMention!(mention);
    _mentionInput = mention;
  }

  void onChanged(String value) async {
    if (onMention == null) return;
    _indexMentionEnd = null;
    String? mention = _getMention(value);
    _updateOnMention(mention);

    if (value.length < _temp.length) {
      _updadeMentions(value);
    }

    _temp = value;
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
      final mentionText = mentionTagDecoration.showMentionStartSymbol
          ? cursorMention.mention
          : "${cursorMention.mentionSymbol}${cursorMention.mention}";
      _updateOnMention(mentionText);
    }
  }

  void _updadeMentions(String value) {
    try {
      final indexCursor = selection.base.offset;

      final mentionsCount = value.countChar(Constants.mentionEscape);
      final textPart = super.text.substring(0, indexCursor);
      final mentionsCountTillCursor =
          textPart.countChar(Constants.mentionEscape);

      _checkAndUpdateOnMention(value, mentionsCountTillCursor, indexCursor);
      if (mentionsCount == _mentions.length) return;

      final removedMention = _mentions.removeAt(mentionsCountTillCursor);

      if (mentionTagDecoration.allowDecrement &&
          _temp.length - value.length == 1) {
        String replacementText = removedMention.mention
            .substring(0, removedMention.mention.length - 1);

        replacementText = mentionTagDecoration.showMentionStartSymbol
            ? replacementText
            : "${removedMention.mentionSymbol}$replacementText";

        super.text =
            super.text.replaceRange(indexCursor, indexCursor, replacementText);

        final offset = mentionTagDecoration.showMentionStartSymbol
            ? indexCursor + removedMention.mention.length - 1
            : indexCursor + removedMention.mention.length;
        selection = TextSelection.collapsed(offset: offset);
        _updateOnMention(replacementText);
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
    final regexp = RegExp(
      '(?=${Constants.mentionEscape})|(?<=${Constants.mentionEscape})',
    );
    final res = super.text.split(regexp);
    final List<MentionTagElement> tempList = List.from(_mentions);

    return TextSpan(
      style: style,
      children: res.map((e) {
        if (e == Constants.mentionEscape) {
          final mention = tempList.removeAt(0);
          final prefix = mention.prefixSymbolInput ?? '';
          final suffix = mention.suffixSymbolInput ?? '';

          return WidgetSpan(
            child: CustomEllipsisText(
              text: prefix + mention.mention + suffix,
              style: mentionTagDecoration.mentionTextStyle,
              maxLines: 1,
            ),
          );
        }

        return TextSpan(text: e, style: style);
      }).toList(),
    );
  }
}
