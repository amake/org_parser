import 'package:petitparser/petitparser.dart';

// Characters marked as line-breakable (`?|`) in Emacs's characters.el

Parser lineBreakable() => pattern('\u2E80-\u312F'
    '\u3190-\u33FF'
    '\u3400-\u9FFF'
    '\uF900-\uFAFF'
    // petitparser doesn't handle codepoints above U+FFFF correctly
    // https://github.com/petitparser/dart-petitparser/issues/80#issuecomment-2510372485
    // TODO(aaron): fix this
    // '\u{20000}-\u{2FFFF}'
    // '\u{30000}-\u{323AF}'
    '་།-༒༔ཿ'
    '་།༏༐༑༔ཿ');
