import 'package:more/char_matcher.dart';
import 'package:petitparser/petitparser.dart';

import 'unicode.dart';

final _letter = UnicodeCharMatcher.letter();
final _number = UnicodeCharMatcher.number();

Parser<int> alnum() =>
    anyCodePoint().where((c) => _letter.match(c) || _number.match(c));

Parser<int> alpha() => anyCodePoint().where((c) => _letter.match(c));
