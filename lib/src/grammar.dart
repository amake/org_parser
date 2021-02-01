library org_parser;

import 'package:org_parser/src/util/util.dart';
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

  Parser headline() => drop(ref(_headline), [-1]);

  Parser _headline() =>
      ref(stars).trim() &
      ref(todoKeyword).trim().optional() &
      ref(priority).trim().optional() &
      ref(title).optional() &
      ref(tags).optional() &
      lineEnd();

  Parser stars() =>
      (lineStart() & char('*').plus() & char(' ')).flatten('Stars expected');

  Parser todoKeyword() => string('TODO') | string('DONE');

  Parser priority() => string('[#') & letter() & char(']');

  Parser title() {
    final limit = ref(tags) | lineEnd();
    return OrgContentGrammar.textRun(limit).plusLazy(limit);
  }

  Parser tags() =>
      string(' :') &
      ref(tag).separatedBy(char(':'), includeSeparators: false) &
      char(':') &
      lineEnd().and();

  Parser tag() => pattern('a-zA-Z0-9_@#%').plus().flatten('Tags expected');

  Parser content() => ref(_content).flatten('Content expected');

  Parser _content() =>
      ref(stars).not() & any().plusLazy(ref(stars) | endOfInput());
}

class OrgContentGrammar extends GrammarParser {
  OrgContentGrammar() : super(OrgContentGrammarDefinition());

  static Parser textRun([Parser limit]) {
    final definition = OrgContentGrammarDefinition();
    return definition.build(start: definition.textRun, arguments: [limit]);
  }
}

class OrgContentGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref(element).star().end();

  Parser element() =>
      ref(block) |
      ref(greaterBlock) |
      ref(latexBlock) |
      ref(affiliatedKeyword) |
      ref(fixedWidthArea) |
      ref(table) |
      ref(list) |
      ref(drawer) |
      ref(footnote) |
      ref(paragraph);

  Parser paragraph() =>
      ref(indent).flatten('Paragraph indent expected') &
      ref(textRun, ref(nonParagraphElements)).plusLazy(ref(paragraphEnd));

  Parser nonParagraphElements() =>
      element()..replace(ref(paragraph), noOpFail());

  Parser paragraphEnd() => endOfInput() | ref(nonParagraphElements);

  Parser textRun([Parser limit]) => ref(object) | ref(plainText, limit);

  Parser object() =>
      ref(link) |
      ref(markups) |
      ref(entity) |
      ref(timestamp) |
      ref(keyword) |
      ref(macroReference) |
      ref(footnoteReference) |
      ref(latexInline);

  Parser plainText([Parser limit]) {
    var fullLimit = ref(object) | endOfInput();
    if (limit != null) {
      fullLimit |= limit;
    }
    return any().plusLazy(fullLimit).flatten('Plain text expected');
  }

  Parser link() => ref(regularLink) | ref(plainLink);

  Parser plainLink() => ref(_plainLink).flatten('Plain link expected');

  Parser _plainLink() => ref(protocol) & char(':') & ref(path2);

  Parser protocol() => string('http') & char('s').optional() | string('mailto');

  Parser path2() => (whitespace() | anyIn('()<>')).neg().plus();

  /*
    Default value of org-link-brackets-re (org-20200302):

    \[\[\(\(?:[^][\]\|\\\(?:\\\\\)*[][]\|\\+[^][]\)+\)]\(?:\[\(\(?:.\|\n\)+?\)]\)?]

    Or in rx form:

    (seq "[["
     (group
      (one-or-more
       (or (not (any "[\\]"))
           (seq "\\"
                (zero-or-more "\\\\")
                (any "[]"))
           (seq (one-or-more "\\")
                (not (any "[]"))))))
     "]"
     (opt "["
          (group
           (+? anything))
          "]")
     "]")
   */

  Parser regularLink() =>
      char('[') & ref(linkPart) & ref(linkDescription).optional() & char(']');

  Parser linkPart() => char('[') & ref(linkPartBody) & char(']');

  Parser linkPartBody() =>
      // Join instead of flatten to drop escape chars
      ref(linkChar).plusLazy(char(']')).map((items) => items.join());

  Parser linkChar() => ref(linkEscape).pick(1) | any();

  Parser linkEscape() => char('\\') & anyOf('[]\\');

  Parser linkDescription() =>
      char('[') &
      // Join instead of flatten to drop escape chars
      ref(anyChar).plusLazy(string(']]')).map((items) => items.join()) &
      char(']');

  Parser anyChar() => ref(escape).pick(0) | any();

  Parser escape() => any() & char('\u200b'); // zero-width space

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

  Parser markup(String marker) => resultPredicate(
        drop(ref(_markup, marker), [0, -1]),
        (result, from, to) {
          for (var count = 0, i = from; i < to; i++) {
            // Ensure at most one LF (U+000A) in markup span
            if (result.codeUnitAt(i) == 0x000A && ++count > 1) {
              return false;
            }
          }
          return true;
        },
      );

  Parser _markup(String marker) =>
      (startOfInput() | was(ref(preMarkup))) &
      char(marker) &
      ref(markupContents, marker).flatten('Markup content expected') &
      char(marker) &
      (ref(postMarkup).and() | endOfInput());

  Parser markupContents(String marker) =>
      ref(markupBorder).and() & ref(markupBody, marker) & ref(markupBorder);

  // The following markupBorder and pre/postMarkup definitions differ from the
  // org-syntax.org document; they have been updated based on the definition of
  // `org-emphasis-regexp-components' in org-20200302.

  Parser markupBorder() => whitespace().neg();

  // TODO(aaron): Simplify this?
  Parser markupBody(String marker) => ref(anyChar)
      .starLazy(
        ref(markupBorder) & char(marker) & (ref(postMarkup) | endOfInput()),
      )
      // Join instead of flatten to drop escape chars
      .map((items) => items.join());

  Parser preMarkup() => whitespace() | anyIn('-(\'"{');

  Parser postMarkup() => whitespace() | anyIn('-.,:!?;\'")}[');

  // Adapted from `org-fontify-entities' in org-20200716

  Parser entity() =>
      char(r'\') &
      ref(entityBody).flatten('Entity body expected') &
      ref(entityEnd).flatten('Entity end expected');

  Parser entityBody() =>
      string('there4') |
      (string('sup') & anyOf('123')) |
      (string('frac') & anyOf('13') & anyOf('24')) |
      pattern('a-zA-Z').plus();

  Parser entityEnd() =>
      // TODO(aaron): PetitParser's letter() is not the same as Emacs's [:alpha:]
      lineEnd().and() | string('{}') | (letter() | char('\n')).not();

  Parser macroReference() =>
      string('{{{') &
      ref(macroReferenceKey).flatten('Macro reference key expected') &
      // TODO(aaron): Actually parse arguments
      ref(macroReferenceArgs)
          .optional()
          .flatten('Macro reference args expected') &
      string('}}}');

  // See `org-element-macro-parser'
  Parser macroReferenceKey() =>
      pattern('a-zA-Z') & pattern('-A-Za-z0-9_').plus();

  Parser macroReferenceArgs() =>
      char('(') & any().starLazy(char(')')) & char(')');

  Parser affiliatedKeyword() => indented(
        ref(affiliatedKeywordBody).flatten('Affiliated keyword body expected'),
      );

  // TODO(aaron): Actually parse real keywords
  Parser affiliatedKeywordBody() => string('#+') & whitespace().neg().plus();

  Parser fixedWidthArea() => ref(fixedWidthLine).plus() & ref(blankLines);

  Parser fixedWidthLine() =>
      ref(indent).flatten('Fixed-width line indent expected') &
      string(': ') &
      ref(lineTrailing).flatten('Trailing line content expected');

  // TODO(aaron): Handle arbitrary blocks? See LatexBlockParser
  Parser block() =>
      ref(namedBlock, 'comment') |
      ref(namedBlock, 'example') |
      ref(namedBlock, 'export') |
      ref(srcBlock) |
      ref(namedBlock, 'verse');

  Parser srcBlock() => indented(
        ref(srcBlockStart) &
            ref(namedBlockContent, 'src') &
            ref(namedBlockEnd, 'src'),
      );

  Parser namedBlock(String name) => indented(
        ref(namedBlockStart, name) &
            ref(namedBlockContent, name) &
            ref(namedBlockEnd, name),
      );

  Parser srcBlockStart() =>
      stringIgnoreCase('#+begin_src') &
      ref(srcBlockLanguageToken).optional() &
      ref(lineTrailing).flatten('Trailing line content expected');

  Parser srcBlockLanguageToken() =>
      ref(insignificantWhitespace)
          .plus()
          .flatten('Separating whitespace expected') &
      whitespace().neg().plus().flatten('Language token expected');

  Parser namedBlockStart(String name) =>
      stringIgnoreCase('#+begin_$name') &
      ref(lineTrailing).flatten('Trailing line content expected');

  Parser namedBlockContent(String name) => ref(namedBlockEnd, name)
      .neg()
      .star()
      .flatten('Named block content expected');

  Parser namedBlockEnd(String name) =>
      ref(indent).flatten('Block end indent expected') &
      stringIgnoreCase('#+end_$name');

  Parser greaterBlock() =>
      ref(namedGreaterBlock, 'quote') | ref(namedGreaterBlock, 'center');

  Parser namedGreaterBlock(String name) => indented(
        ref(namedBlockStart, name) &
            namedGreaterBlockContent(name) &
            ref(namedBlockEnd, name),
      );

  Parser namedGreaterBlockContent(String name) {
    final end = ref(namedBlockEnd, name);
    return ref(textRun, end).starLazy(end);
  }

  Parser indent() => lineStart() & ref(insignificantWhitespace).star();

  Parser indented(Parser parser) =>
      ref(indent).flatten('Indent expected') &
      parser &
      (ref(lineTrailing) & ref(blankLines))
          .flatten('Trailing line content expected');

  Parser blankLines() =>
      Token.newlineParser().star().flatten('Blank lines expected');

  Parser lineTrailing() => any().starLazy(lineEnd()) & lineEnd();

  Parser lineTrailingWhitespace() =>
      ref(insignificantWhitespace).starLazy(lineEnd()) & lineEnd();

  Parser insignificantWhitespace() => anyOf(' \t');

  Parser table() => ref(tableLine).plus() & blankLines();

  Parser tableLine() => ref(tableRow) | ref(tableDotElDivider);

  Parser tableRow() => ref(tableRowRule) | ref(tableRowStandard);

  Parser tableRowStandard() =>
      ref(indent).flatten('Table row indent expected') &
      char('|') &
      ref(tableCell).star() &
      ref(lineTrailing).flatten('Trailing line content expected');

  Parser tableCell() =>
      ref(tableCellLeading).flatten('Cell leading content expected') &
      ref(tableCellContents) &
      ref(tableCellTrailing).flatten('Cell trailing content expected');

  Parser tableCellLeading() => char(' ').star();

  Parser tableCellTrailing() => char(' ').star() & char('|');

  Parser tableCellContents() {
    final end = ref(tableCellTrailing) | lineEnd();
    return ref(textRun, end).starLazy(end);
  }

  Parser tableRowRule() =>
      ref(indent).flatten('Table row rule indent expected') &
      (string('|-') & ref(lineTrailing))
          .flatten('Trailing line content expected');

  Parser tableDotElDivider() =>
      ref(indent).flatten('Table.el divider indent expected') &
      (string('+-') & anyOf('+-').star()).flatten('Table divider expected') &
      ref(lineTrailing).flatten('Trailing line content expected');

  Parser timestamp() =>
      ref(timestampDiary) |
      ref(timestampRange, true) |
      ref(timestampRange, false) |
      ref(timestampSimple, true) |
      ref(timestampSimple, false);

  Parser timestampDiary() => string('<%%') & ref(sexp) & char('>');

  // TODO(aaron): Bother with a real Elisp parser here?
  Parser sexp() => ref(sexpAtom) | ref(sexpList);

  Parser sexpAtom() =>
      (anyOf('()') | whitespace()).neg().plus().flatten('Expected atom');

  Parser sexpList() => char('(') & ref(sexp).trim().star() & char(')');

  Parser timestampSimple(bool active) =>
      (active ? char('<') : char('[')) &
      ref(date) &
      ref(time).trim().optional() &
      ref(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampRange(bool active) =>
      ref(timestampTimeRange, active) | ref(timestampDateRange, active);

  Parser timestampTimeRange(bool active) =>
      (active ? char('<') : char('[')) &
      ref(date) &
      (ref(time) & char('-') & ref(time)).trim() &
      ref(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampDateRange(bool active) =>
      ref(timestampSimple, active) &
      char('-').repeat(1, 3).flatten('Expected timestamp separator') &
      ref(timestampSimple, active);

  Parser date() =>
      ref(year) &
      char('-') &
      ref(month) &
      char('-') &
      ref(day) &
      dayName().trim();

  Parser year() => digit().times(4).flatten('Expected year');

  Parser month() => digit().times(2).flatten('Expected month');

  Parser day() => digit().times(2).flatten('Expected day');

  Parser dayName() => (whitespace() | anyOf('+-]>\n') | digit())
      .neg()
      .plus()
      .flatten('Expected day name');

  Parser time() => ref(hours) & char(':') & ref(minutes);

  Parser hours() => digit().repeat(1, 2).flatten('Expected hours');

  Parser minutes() => digit().times(2).flatten('Expected minutes');

  Parser repeaterOrDelay() =>
      ref(repeaterMark) &
      digit().plus().flatten('Expected number') &
      ref(repeaterUnit);

  Parser repeaterMark() =>
      string('++') | string('.+') | string('--') | anyOf('+-');

  Parser repeaterUnit() => anyOf('hdwmy');

  Parser keyword() => ref(_keyword).flatten('Expected keyword');

  Parser _keyword() =>
      string('SCHEDULED:') |
      string('DEADLINE:') |
      string('CLOCK:') |
      string('CLOSED:');

  Parser list() => ref(listItem).plus() & ref(blankLines);

  Parser listItem() => ref(listItemUnordered) | ref(listItemOrdered);

  Parser listItemUnordered() =>
      (ref(indent) & ref(listUnorderedBullet).and())
          .flatten('List item (unordered) indent expected') &
      indentedRegion(
        parser: ref(listUnorderedBullet).flatten('Unordered bullet expected') &
            ref(listCheckBox).trim(char(' ')).optional() &
            ref(listTag).trim(char(' ')).optional() &
            ref(listItemContents),
        indentAdjust: 1,
        maxSeparatingLineBreaks: 2,
      );

  Parser listUnorderedBullet() => anyOf('*-+') & char(' ');

  Parser listTag() {
    final end = string(' ::') & (lineEnd() | char(' '));
    final limit = end | lineEnd();
    return ref(textRun, limit).plusLazy(limit) &
        end.flatten('List tag end expected');
  }

  Parser listItemOrdered() =>
      (ref(indent) & ref(listOrderedBullet).and())
          .flatten('List item (ordered) indent expected') &
      indentedRegion(
        parser: ref(listOrderedBullet) &
            ref(listCounterSet).trim(char(' ')).optional() &
            ref(listCheckBox).trim(char(' ')).optional() &
            ref(listItemContents),
        indentAdjust: 1,
        maxSeparatingLineBreaks: 2,
      );

  Parser listOrderedBullet() =>
      (digit().plus().flatten('Bullet number expected') | letter()) &
      anyOf('.)') &
      char(' ');

  Parser listCounterSet() =>
      string('[@') &
      digit().plus().flatten('Counter set number expected') &
      char(']');

  Parser listCheckBox() => char('[') & anyOf(' -X') & char(']');

  Parser listItemContents() {
    final end =
        ref(listItemAnyStart) | ref(nonParagraphElements) | endOfInput();
    return (ref(element) | ref(textRun, end)).star();
  }

  Parser listItemAnyStart() =>
      ref(indent) & (ref(listUnorderedBullet) | ref(listOrderedBullet));

  Parser drawer() => indented(
        ref(drawerStart) & ref(drawerContent) & ref(drawerEnd),
      );

  Parser drawerStart() =>
      char(':') &
      pattern('a-zA-Z0-9_@#%')
          .plusLazy(char(':'))
          .flatten('Drawer start expected') &
      char(':') &
      lineTrailingWhitespace().flatten('Trailing whitespace expected');

  Parser drawerContent() {
    final end = ref(drawerEnd);
    return (ref(property) | ref(nonDrawerElements) | ref(textRun, end))
        .starLazy(end);
  }

  Parser nonDrawerElements() => element()..replace(ref(drawer), noOpFail());

  Parser drawerEnd() =>
      ref(indent).flatten('Drawer end indent expected') &
      (stringIgnoreCase(':END:') & ref(insignificantWhitespace).star())
          .flatten('Drawer end expected');

  Parser property() =>
      ref(indent).flatten('Property indent expected') &
      ref(propertyKey) &
      ref(propertyValue) &
      (lineEnd() & ref(blankLines)).flatten('Trailing whitespace expected');

  Parser propertyKey() =>
      char(':') &
      any()
          .plusLazy(
            char(':') & ref(insignificantWhitespace).plus() & lineEnd().not(),
          )
          .flatten('Property name expected') &
      char(':');

  Parser propertyValue() =>
      any().plusLazy(lineEnd()).flatten('Property value expected');

  Parser footnoteReference() =>
      ref(footnoteReferenceNamed) | ref(footnoteReferenceInline);

  Parser footnoteReferenceNamed() =>
      string('[fn:') & ref(footnoteName) & char(']');

  Parser footnoteReferenceInline() =>
      string('[fn:') &
      ref(footnoteName).optional() &
      char(':') &
      ref(footnoteDefinition) &
      char(']');

  Parser footnoteName() =>
      pattern('-_A-Za-z0-9').plus().flatten('Footnote name expected');

  Parser footnoteDefinition() => textRun(char(']')).plusLazy(char(']'));

  Parser footnote() => drop(ref(_footnote), [0]);

  Parser _footnote() =>
      lineStart() &
      ref(footnoteReferenceNamed) &
      ref(footnoteBody) &
      Token.newlineParser()
          .repeat(0, 3)
          .flatten('Footnote trailing content expected');

  Parser footnoteBody() {
    final end = endOfInput() |
        lineStart() & ref(footnoteReferenceNamed) |
        Token.newlineParser().repeat(3);
    return ref(textRun, end).plusLazy(end);
  }

  Parser latexBlock() => indented(LatexBlockParser());

  Parser latexInline() =>
      ref(_latexInline, r'$$', r'$$') |
      ref(_latexInline, r'\(', r'\)') |
      ref(_latexInline, r'\[', r'\]') |
      drop(_markup(r'$'), [0, -1]);

  Parser _latexInline(String start, String end) =>
      string(start) &
      string(end).neg().plusLazy(string(end)).flatten('LaTeX body expected') &
      string(end);
}
