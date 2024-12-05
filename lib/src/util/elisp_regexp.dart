import 'package:more/char_matcher.dart';
import 'package:petitparser/petitparser.dart';

import 'unicode.dart';

final _letter = UnicodeCharMatcher.letter();
final _number = UnicodeCharMatcher.number();
final _currency = UnicodeCharMatcher.symbolCurrency();
final _otherPunct = UnicodeCharMatcher.punctuationOther();
final _modifier = UnicodeCharMatcher.symbolModifier();

Parser<int> alnum() =>
    anyCodePoint().where((c) => _letter.match(c) || _number.match(c));

Parser<int> alpha() => anyCodePoint().where((c) => _letter.match(c));

// Emacs's [:word:] is based on the syntax table. In particular we would care
// about the Org Mode syntax table. It's not feasible to reproduce that here, so
// we approximate it.
Parser<int> word() => anyCodePoint().where((c) =>
    _letter.match(c) ||
    _number.match(c) ||
    _currency.match(c) ||
    (c > 0xff && (_otherPunct.match(c) || _modifier.match(c))) ||
    switch (c) {
      // % ' ·
      0x25 || 0x27 || 0xb7 => true,
      _ => false,
    });
