library org_parser;

import 'package:org_parser/src/util.dart';
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

  Parser content() => ref(_content).flatten();

  Parser _content() =>
      char('*').not() &
      (ref(newline) & (char('*'))).neg().plus() &
      ref(newline).optional();

  Parser newline() => Token.newlineParser();

  Parser trailingWhitespace() => anyIn(' \t').star() & ref(newline);
}

class OrgContentGrammar extends GrammarParser {
  OrgContentGrammar() : super(OrgContentGrammarDefinition());
}

class OrgContentGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref(textRun).star().end();

  Parser textRun() => ref(objects) | ref(plainText);

  Parser objects() => ref(link) | ref(markups) | ref(meta) | ref(codeLine);

  Parser plainText() => ref(objects).neg().plus().flatten();

  Parser link() => ref(regularLink) | ref(plainLink);

  Parser plainLink() => ref(_plainLink).flatten();

  Parser _plainLink() => ref(protocol) & char(':') & ref(path2);

  Parser protocol() => string('http') & char('s').optional() | string('mailto');

  Parser path2() => (whitespace() | anyIn('()<>')).neg().plus();

  Parser regularLink() =>
      char('[') & ref(linkPart) & ref(linkPart).optional() & char(']');

  Parser linkPart() => char('[') & char(']').neg().plus().flatten() & char(']');

  Parser markups() =>
      ref(bold) |
      ref(verbatim) |
      ref(italic) |
      ref(strikeThrough) |
      ref(underline) |
      ref(code);

  Parser bold() => ref(markup, '*');

  Parser verbatim() => ref(markup, '=');

  Parser italic() => ref(markup, '/');

  Parser strikeThrough() => ref(markup, '+');

  Parser underline() => ref(markup, '_');

  Parser code() => ref(markup, '~');

  Parser markup(String marker) => drop(ref(_markup, marker), [0, -1]);

  Parser _markup(String marker) =>
      (startOfInput() | was(ref(preMarkup))) &
      char(marker) &
      ref(markupContents, marker).flatten() &
      char(marker) &
      (ref(postMarkup).and() | endOfInput());

  Parser markupContents(String marker) =>
      ref(markupBorder).and() & ref(markupBody, marker) & ref(markupBorder);

  Parser markupBorder() => (whitespace() | anyIn(',\'"')).neg();

  Parser markupBody(String marker) =>
      (ref(markupBorder) & char(marker)).neg().star();

  Parser preMarkup() => whitespace() | anyIn('({\'"');

  Parser postMarkup() => whitespace() | anyIn('-.,:!?\')}"');

  Parser meta() => ref(_meta).flatten();

  Parser _meta() =>
      lineStart() &
      whitespace().star() &
      string('#+') &
      Token.newlineParser().neg().plus();

  Parser codeLine() => ref(_codeLine).flatten();

  Parser _codeLine() =>
      lineStart() &
      whitespace().star() &
      char(':') &
      Token.newlineParser().neg().star();
}
