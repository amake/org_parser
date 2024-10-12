import 'package:more/char_matcher.dart';
import 'package:petitparser/petitparser.dart';

Parser alnum() => any().where((char) {
      final c = char.codeUnitAt(0);
      return UnicodeCharMatcher.letter().match(c) ||
          UnicodeCharMatcher.number().match(c);
    });
