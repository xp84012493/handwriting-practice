import 'package:lpinyin/lpinyin.dart';

/// 汉字拼音（带声调符号）。
abstract final class HanziPinyin {
  static String forCharacter(String character) {
    if (character.isEmpty) return '';
    return PinyinHelper.getPinyin(
      character,
      separator: '',
      format: PinyinFormat.WITH_TONE_MARK,
    );
  }
}
