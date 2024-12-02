import 'package:more/char_matcher.dart';
import 'package:petitparser/petitparser.dart';

import 'unicode.dart';

Parser<int> alnum() => anyCodePoint().where((c) =>
    UnicodeCharMatcher.letter().match(c) ||
    UnicodeCharMatcher.number().match(c));
