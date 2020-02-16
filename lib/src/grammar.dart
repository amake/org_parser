library org_parser;

import 'package:petitparser/petitparser.dart';

// See https://orgmode.org/worg/dev/org-syntax.html

class OrgGrammar extends GrammarParser {
  OrgGrammar() : super(OrgGrammarDefinition());
}

class OrgGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref(document).end();

  Parser document() => ref(content).optional() & ref(section).star();

  Parser section() => ref(headline) & ref(content).optional();

  Parser headline() =>
      ref(stars).trim() &
      _headlinePartTrim(ref(keyword)).optional() &
      _headlinePartTrim(ref(priority)).optional() &
      _headlinePartTrim(ref(title)).optional() &
      _headlinePartTrim(ref(tags)).optional();

  Parser _headlinePartTrim(Parser parser) =>
      parser.trim(whitespace(), ref(trailingWhitespace));

  Parser stars() => char('*').plus().flatten();

  Parser keyword() => string('TODO') | string('DONE');

  Parser priority() => string('[#') & letter() & char(']');

  Parser title() => ref(newline).neg().star().flatten();

  Parser tags() =>
      char(':') &
      (pattern('a-zA-Z0-9_@#%').plus().flatten() & char(':')).star();

  Parser content() => (char('*').not() & ref(line)).pick(1).plus().flatten();

  Parser line() =>
      (ref(newline).neg().plus() & ref(newline).optional()) | ref(newline);

  Parser newline() => Token.newlineParser();

  Parser trailingWhitespace() => anyIn(' \t').star() & ref(newline);
}
