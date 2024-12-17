import 'package:org_parser/src/todo/model.dart';
import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart' hide word;

// See https://orgmode.org/worg/dev/org-syntax.html

/// Top-level grammar definition
///
/// This describes the overall structure of an Org document:
/// - Leading content
/// - One or more sections
///   - Headline
///   - Content
///   - One or more sections
///     - etc.
///
/// The structure and the content turned out to be hard to define together, so
/// the content rules are defined separately in [OrgContentGrammarDefinition].
class OrgGrammarDefinition extends GrammarDefinition {
  const OrgGrammarDefinition({this.todoStates});

  /// Equivalent to `org-todo-keywords`. If not provided (null), defaults to
  /// [defaultTodoStates].
  final List<OrgTodoStates>? todoStates;
  List<OrgTodoStates> get effectiveTodoStates =>
      todoStates ?? [defaultTodoStates];

  @override
  Parser start() => ref0(document).end();

  Parser document() => ref0(content).optional() & ref0(section).star();

  Parser section() => ref0(headline) & ref0(content).optional();

  Parser headline() => (lineStart() &
          ref0(stars) &
          ref0(todoKeyword).optional() &
          ref0(priority).optional() &
          ref0(title).optional() &
          ref0(tags).optional() &
          lineEnd())
      .drop1(0);

  Parser stars() => char('*').plusString() & char(' ').plusString();

  Parser todoKeyword() {
    final choices = effectiveTodoStates.fold(
      <Parser>[],
      (acc, e) => acc
        ..addAll(e.todo.map(string))
        ..addAll(e.done.map(string)),
    );
    return choices.isNotEmpty
        ? choices.toChoiceParser() & char(' ').starString()
        : failure();
  }

  Parser priority() =>
      string('[#') &
      letter() &
      (char(']') & char(' ').starString())
          .flatten('Priority trailing expected');

  Parser title() {
    final limit = ref0(tags) | lineEnd();
    return newline().neg().plusLazy(limit).flatten('Title expected');
  }

  Parser tags() => (was(char(' ')) &
          string(':') &
          ref0(tag).plusSeparated(char(':')) &
          char(':') &
          lineEnd().and())
      .drop1(0);

  Parser tag() => (alnum() | anyOf('_@#%')).plus().flatten('Tags expected');

  Parser content() => ref0(_content).flatten('Content expected');

  Parser _content() =>
      ref0(headline).not() & any().plusLazy(ref0(headline) | endOfInput());
}

/// Content grammar definition
///
/// These rules cover all "content", as opposed to "structure". See
/// [OrgGrammarDefinition].
class OrgContentGrammarDefinition extends GrammarDefinition {
  const OrgContentGrammarDefinition({this.radioTargets});

  /// Plain-text strings to be linked to a `<<<radio target>>>`.
  final List<String>? radioTargets;

  @override
  Parser start() => ref0(element).star().end();

  Parser element() =>
      ref0(block) |
      ref0(greaterBlock) |
      ref0(arbitraryGreaterBlock) |
      ref0(latexBlock) |
      ref0(affiliatedKeyword) |
      ref0(fixedWidthArea) |
      ref0(table) |
      ref0(horizontalRule) |
      ref0(list) |
      ref0(planningLine) |
      ref0(drawer) |
      ref0(footnote) |
      ref0(localVariables) |
      ref0(pgpBlock) |
      ref0(comment) |
      ref0(paragraph);

  Parser paragraph() =>
      ref0(indent).flatten('Paragraph indent expected') &
      ref1(textRun, ref0(paragraphEnd)).plusLazy(ref0(paragraphEnd)) &
      ref0(blankLines);

  Parser nonParagraphElements() =>
      element()..replace(ref0(paragraph), noOpFail());

  Parser paragraphEnd() =>
      endOfInput() | newline().repeatString(2) | ref0(nonParagraphElements);

  Parser textRun([Parser? limit]) => ref0(object) | ref1(plainText, limit);

  Parser nonLinkTextRun([Parser? limit]) =>
      ref0(nonLinkObjects) | ref1(plainText, limit);

  Parser object() =>
      ref0(link) |
      ref0(linkTarget) |
      ref0(radioTarget) |
      ref0(radioLink) |
      ref0(markups) |
      ref0(entity) |
      ref0(subscript) |
      ref0(superscript) |
      ref0(timestamp) |
      ref0(keyword) |
      ref0(macroReference) |
      ref0(footnoteReference) |
      ref0(citation) |
      ref0(latexInline) |
      ref0(statsCookie);

  Parser nonLinkObjects() => object()..replace(ref0(link), noOpFail());

  Parser plainText([Parser? limit]) {
    var fullLimit = ref0(object) | endOfInput();
    if (limit != null) {
      fullLimit |= limit;
    }
    return any().plusLazy(fullLimit).flatten('Plain text expected');
  }

  Parser link() => ref0(regularLink) | ref0(plainLink);

  Parser plainLink() => ref0(_plainLink).flatten('Plain link expected');

  Parser _plainLink() => ref0(protocol) & char(':') & ref0(path2);

  // Built-in link types only
  Parser protocol() =>
      string('https') |
      string('http') |
      string('doi') |
      string('file') |
      string('attachment') |
      string('docview') |
      string('id') |
      string('news') |
      string('mailto') |
      string('mhe') |
      string('rmail') |
      string('gnus') |
      string('bbdb') |
      string('irc') |
      string('help') |
      string('info') |
      string('shell') |
      string('elisp');

  Parser path2() => (whitespace() | anyOf('()<>')).neg().plus();

  /*
    Default value of org-link-bracket-re (org 9.6.6):

    \[\[\(\(?:[^][\]\|\\\(?:\\\\\)*[][]\|\\+[^][]\)+\)]\(?:\[\([^z-a]+?\)]\)?]

    Or in rx form via (pp (xr org-link-bracket-re)):

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
      char('[') & ref0(linkPart) & ref0(linkDescription).optional() & char(']');

  Parser linkPart() => char('[') & ref0(linkPartBody) & char(']');

  Parser linkPartBody() =>
      // Join instead of flatten to drop escape chars
      ref0(linkChar).plusLazy(char(']')).map((items) => items.join());

  Parser linkChar() => ref0(linkEscape).castList<String>().pick(1) | any();

  Parser linkEscape() => char(r'\') & anyOf(r'[]\');

  Parser linkDescription() =>
      char('[') &
      // Join instead of flatten to drop escape chars
      ref0(anyChar).plusLazy(string(']]')).map((items) => items.join()) &
      char(']');

  Parser anyChar() => ref0(escape) | any();

  // zero-width space
  Parser escape() => seq2(any(), char('\u200b')).map2((c, _) => c);

  Parser linkTarget() =>
      string('<<') &
      ref0(linkTargetContent).flatten('Target content expected') &
      string('>>');

  Parser linkTargetContent() =>
      ref0(linkTargetBorder).and() &
      anyOf('<>\n\r').neg().starLazy(ref0(linkTargetBorder) & string('>>')) &
      ref0(linkTargetBorder);

  Parser linkTargetBorder() => anyOf('<>\n\r \t').neg();

  Parser radioTarget() =>
      string('<<<') &
      ref0(linkTargetContent).flatten('Target content expected') &
      string('>>>');

  Parser radioLink() => radioTargets?.isNotEmpty == true
      ? ref1(radioLinkImpl, radioTargets!)
      : failure();

  Parser radioLinkImpl(List<String> targets) =>
      ref0(radioLinkBefore) &
      targets.map(stringIgnoreCase).toChoiceParser() &
      ref0(radioLinkAfter);

  Parser radioLinkBefore() =>
      lineStart() | was(alnum().neg() | lineBreakable());

  Parser radioLinkAfter() =>
      lineEnd().and() | alnum().not() | lineBreakable().and();

  Parser markups() =>
      ref0(bold) |
      ref0(verbatim) |
      ref0(italic) |
      ref0(strikeThrough) |
      ref0(underline) |
      ref0(code);

  Parser bold() => ref1(markup, '*');

  Parser verbatim() => ref1(markup, '=');

  Parser italic() => ref1(markup, '/');

  Parser strikeThrough() => ref1(markup, '+');

  Parser underline() => ref1(markup, '_');

  Parser code() => ref1(markup, '~');

  Parser markup(String marker) =>
      ref1(_markup, marker).drop([0, -1]).castList<String>().where((value) {
            final content = value[1];
            for (var count = 0, i = 0; i < content.length; i++) {
              // Ensure at most one LF (U+000A) in markup span
              if (content.codeUnitAt(i) == 0x000A && ++count > 1) {
                return false;
              }
            }
            return true;
          });

  Parser _markup(String marker) =>
      (startOfInput() | was(ref0(preMarkup))) &
      char(marker) &
      ref1(markupContents, marker).flatten('Markup content expected') &
      char(marker) &
      (ref0(postMarkup).and() | endOfInput());

  Parser markupContents(String marker) =>
      ref0(markupBorder).and() & ref1(markupBody, marker) & ref0(markupBorder);

  // The following markupBorder and pre/postMarkup definitions differ from the
  // org-syntax.org document; they have been updated based on the definition of
  // `org-emphasis-regexp-components' in org-20200302.

  Parser markupBorder() => whitespace().neg();

  // TODO(aaron): Simplify this?
  Parser markupBody(String marker) => ref0(anyChar)
      .starLazy(
        ref0(markupBorder) & char(marker) & (ref0(postMarkup) | endOfInput()),
      )
      // Join instead of flatten to drop escape chars
      .map((items) => items.join());

  Parser preMarkup() => whitespace() | anyOf('-(\'"{');

  Parser postMarkup() => whitespace() | anyOf('-.,:!?;\'")}[');

  // Adapted from `org-fontify-entities' in org-20200716

  Parser entity() =>
      char(r'\') &
      ref0(entityBody).flatten('Entity body expected') &
      ref0(entityEnd).flatten('Entity end expected');

  Parser entityBody() =>
      string('there4') |
      (string('sup') & anyOf('123')) |
      (string('frac') & anyOf('13') & anyOf('24')) |
      pattern('a-zA-Z').plus();

  Parser entityEnd() => lineEnd().and() | string('{}') | alpha().not();

  Parser subscript() => (was(whitespace().neg()) &
          char('_') &
          ref0(subSuperscriptBody).flatten('Subscript body expected'))
      .drop1(0);

  Parser superscript() => (was(whitespace().neg()) &
          char('^') &
          ref0(subSuperscriptBody).flatten('Superscript body expected'))
      .drop1(0);

  // "Reverse ID" is not an Org concept; it's the reverse of the identifier
  // example parser in the PetitParser readme; see
  // https://github.com/petitparser/dart-petitparser/discussions/178
  Parser reverseId(Parser inner, Parser terminator) =>
      inner.starLazy(terminator & inner.not()) & terminator;

  // See `org-match-substring-regexp`
  Parser subSuperscriptBody() =>
      ref1(sexpList, '{}') |
      ref0(sexpList) |
      char('*') |
      (anyOf('+-').optional() & reverseId(alnum() | anyOf(r'.,\'), alnum()));

  Parser macroReference() =>
      string('{{{') &
      ref0(macroReferenceKey).flatten('Macro reference key expected') &
      // TODO(aaron): Actually parse arguments
      ref0(macroReferenceArgs)
          .optional()
          .flatten('Macro reference args expected') &
      string('}}}');

  // See `org-element-macro-parser'
  Parser macroReferenceKey() =>
      pattern('a-zA-Z') & pattern('-A-Za-z0-9_').plusString();

  Parser macroReferenceArgs() =>
      char('(') & any().starLazy(char(')')) & char(')');

  Parser affiliatedKeyword() => indented(
        ref0(affiliatedKeywordBody).flatten('Affiliated keyword body expected'),
      );

  // TODO(aaron): Actually parse real keywords
  Parser affiliatedKeywordBody() =>
      string('#+') & whitespace().neg().plusString();

  Parser fixedWidthArea() => ref0(fixedWidthLine).plus() & ref0(blankLines);

  Parser fixedWidthLine() =>
      ref0(indent).flatten('Fixed-width line indent expected') &
      string(': ') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser localVariables() => localVariablesParser() & ref0(blankLines);

  Parser pgpBlock() =>
      indented(ref0(pgpBlockStart) & ref0(pgpBlockBody) & ref0(pgpBlockEnd));

  Parser pgpBlockStart() => string('-----BEGIN PGP MESSAGE-----');

  Parser pgpBlockBody() =>
      any().starLazy(ref0(pgpBlockEnd)).flatten('PGP block body expected');

  Parser pgpBlockEnd() => string('-----END PGP MESSAGE-----');

  Parser comment() =>
      ref0(indent).flatten('Comment indent expected') &
      (char('#') & anyOf(' \t')).flatten('Comment start expected') &
      newline().neg().starString('Comment content expected') &
      ref0(blankLines);

  Parser block() =>
      ref1(namedBlock, 'comment') |
      ref1(namedBlock, 'example') |
      ref1(namedBlock, 'export') |
      ref0(srcBlock) |
      ref1(namedBlock, 'verse');

  Parser srcBlock() => indented(
        ref0(srcBlockStart) &
            ref1(namedBlockContent, 'src') &
            ref1(namedBlockEnd, 'src'),
      );

  Parser namedBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            ref1(namedBlockContent, name) &
            ref1(namedBlockEnd, name),
      );

  Parser srcBlockStart() =>
      stringIgnoreCase('#+begin_src') &
      ref0(srcBlockLanguageToken).optional() &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser srcBlockLanguageToken() =>
      insignificantWhitespace().plusString('Separating whitespace expected') &
      whitespace().neg().plusString('Language token expected');

  Parser namedBlockStart(String name) =>
      stringIgnoreCase('#+begin_$name') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser namedBlockContent(String name) => ref1(namedBlockEnd, name)
      .neg()
      .starString('Named block content expected');

  Parser namedBlockEnd(String name) =>
      ref0(indent).flatten('Block end indent expected') &
      stringIgnoreCase('#+end_$name');

  Parser greaterBlock() =>
      ref1(namedGreaterBlock, 'quote') | ref1(namedGreaterBlock, 'center');

  Parser namedGreaterBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            namedGreaterBlockContent(name) &
            ref1(namedBlockEnd, name),
      );

  Parser namedGreaterBlockContent(String name) {
    final end = ref1(namedBlockEnd, name);
    return ref1(textRun, end).starLazy(end);
  }

  Parser arbitraryGreaterBlock() => indented(blockParser(ref0(textRun).star()));

  Parser indent() => lineStart() & insignificantWhitespace().starString();

  Parser indented(Parser parser) =>
      ref0(indent).flatten('Indent expected') &
      parser &
      (ref0(lineTrailing) & ref0(blankLines))
          .flatten('Trailing line content expected');

  Parser blankLines() => newline().starString('Blank lines expected');

  Parser lineTrailing() => any().starLazy(lineEnd()) & lineEnd();

  Parser lineTrailingWhitespace() =>
      insignificantWhitespace().starLazy(lineEnd()) & lineEnd();

  Parser table() => ref0(tableLine).plus() & blankLines();

  Parser tableLine() => ref0(tableRow) | ref0(tableDotElDivider);

  Parser tableRow() => ref0(tableRowRule) | ref0(tableRowStandard);

  Parser tableRowStandard() =>
      ref0(indent).flatten('Table row indent expected') &
      char('|') &
      ref0(tableCell).star() &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser tableCell() =>
      ref0(tableCellLeading) &
      ref0(tableCellContents) &
      ref0(tableCellTrailing).flatten('Cell trailing content expected');

  Parser tableCellLeading() => char(' ').starString();

  Parser tableCellTrailing() => char(' ').starString() & char('|');

  Parser tableCellContents() {
    final end = ref0(tableCellTrailing) | lineEnd();
    return ref1(textRun, end).starLazy(end);
  }

  Parser tableRowRule() =>
      ref0(indent).flatten('Table row rule indent expected') &
      (string('|-') & anyOf('-+').starString() & char('|'))
          .flatten('Trailing line content expected') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser tableDotElDivider() =>
      ref0(indent).flatten('Table.el divider indent expected') &
      (string('+-') & anyOf('+-').starString())
          .flatten('Table divider expected') &
      ref0(lineTrailing).flatten('Trailing line content expected');

  Parser horizontalRule() =>
      ref0(indent).flatten('Indent expected') &
      char('-').repeatString(5, unbounded) &
      (ref0(lineTrailingWhitespace) & ref0(blankLines)).flatten();

  Parser timestamp() =>
      ref0(timestampDiary) |
      ref1(timestampRange, true) |
      ref1(timestampRange, false) |
      ref1(timestampSimple, true) |
      ref1(timestampSimple, false);

  Parser timestampDiary() =>
      string('<%%') & ref0(sexp) & char('>').neg().starString() & char('>');

  // TODO(aaron): Bother with a real Elisp parser here?
  Parser sexp([String delimiters = '()']) =>
      ref1(sexpAtom, delimiters) | ref1(sexpList, delimiters);

  Parser sexpAtom([String delimiters = '()']) =>
      (anyOf(delimiters) | whitespace()).neg().plusString('Expected atom');

  Parser sexpList([String delimiters = '()']) =>
      char(delimiters[0]) &
      ref1(sexp, delimiters).trim().star() &
      char(delimiters[1]);

  Parser timestampSimple(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      ref0(time).trim().optional() &
      ref0(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampRange(bool active) =>
      ref1(timestampTimeRange, active) | ref1(timestampDateRange, active);

  Parser timestampTimeRange(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      (ref0(time) & char('-') & ref0(time)).trim() &
      ref0(repeaterOrDelay).trim().repeat(0, 2) &
      (active ? char('>') : char(']'));

  Parser timestampDateRange(bool active) =>
      ref1(timestampSimple, active) &
      char('-').repeatString(1, 3, 'Expected timestamp separator') &
      ref1(timestampSimple, active);

  Parser date() =>
      ref0(year) &
      char('-') &
      ref0(month) &
      char('-') &
      ref0(day) &
      dayName().trim();

  Parser year() => digit().timesString(4, 'Expected year');

  Parser month() => digit().timesString(2, 'Expected month');

  Parser day() => digit().timesString(2, 'Expected day');

  Parser dayName() => (whitespace() | anyOf('+-]>\n') | digit())
      .neg()
      .plusString('Expected day name');

  Parser time() => ref0(hours) & char(':') & ref0(minutes);

  Parser hours() => digit().repeatString(1, 2, 'Expected hours');

  Parser minutes() => digit().timesString(2, 'Expected minutes');

  Parser repeaterOrDelay() =>
      ref0(repeaterMark) &
      digit().plusString('Expected number') &
      ref0(repeaterUnit);

  Parser repeaterMark() =>
      string('++') | string('.+') | string('--') | anyOf('+-');

  Parser repeaterUnit() => anyOf('hdwmy');

  Parser keyword() => ref0(_keyword).flatten('Expected keyword');

  Parser _keyword() =>
      string('SCHEDULED:') |
      string('DEADLINE:') |
      string('CLOCK:') |
      string('CLOSED:');

  Parser planningLine() => indented(ref0(_planningLine));

  Parser _planningLine() {
    final limit = lineEnd();
    return ref0(keyword) & ref1(textRun, limit).plusLazy(limit);
  }

  Parser list() => ref0(listItem).plus() & ref0(blankLines);

  Parser listItem() => ref0(listItemUnordered) | ref0(listItemOrdered);

  Parser listItemUnordered() =>
      ref0(listItemUnorderedIndent).flatten('indent expected') &
      ref0(listUnorderedBullet) &
      indentedRegion(
        parser: char(' ').starString() &
            ref0(listCheckBox).trim(char(' ')).optional() &
            ref0(listTag).trim(char(' ')).optional() &
            ref0(listItemContents),
      );

  Parser listItemUnorderedIndent() =>
      ref0(indent) & (ref0(listUnorderedBullet) & char(' ')).and();

  Parser listUnorderedBullet() => anyOf('*-+');

  Parser listTag() {
    final end = string(' ::') & (lineEnd().and() | char(' '));
    final limit = end | lineEnd();
    return ref1(textRun, limit).plusLazy(limit) &
        end.flatten('List tag end expected');
  }

  Parser listItemOrdered() =>
      ref0(listItemOrderedIndent).flatten('indent expected') &
      ref0(listOrderedBullet).flatten('Ordered bullet expected') &
      indentedRegion(
        parser: char(' ').starString() &
            ref0(listCounterSet).trim(char(' ')).optional() &
            ref0(listCheckBox).trim(char(' ')).optional() &
            ref0(listItemContents),
      );

  Parser listItemOrderedIndent() =>
      ref0(indent) & (ref0(listOrderedBullet) & char(' ')).and();

  Parser listOrderedBullet() =>
      (digit().plusString('Bullet number expected') | letter()) & anyOf('.)');

  Parser listCounterSet() =>
      string('[@') &
      digit().plusString('Counter set number expected') &
      char(']');

  Parser listCheckBox() => char('[') & anyOf(' -X') & char(']');

  Parser listItemContents() {
    final end =
        ref0(listItemAnyStart) | ref0(nonParagraphElements) | endOfInput();
    return (ref0(element) | ref1(textRun, end)).star();
  }

  Parser listItemAnyStart() =>
      ref0(indent) & (ref0(listUnorderedBullet) | ref0(listOrderedBullet));

  Parser statsCookie() => ref0(statsCookieFraction) | ref0(statsCookiePercent);

  Parser statsCookieFraction() =>
      char('[') &
      pattern('0-9').starString() &
      char('/') &
      pattern('0-9').starString() &
      char(']');

  Parser statsCookiePercent() =>
      char('[') & pattern('0-9').starString() & char('%') & char(']');

  Parser drawer() => indented(
        ref0(drawerStart) & ref0(drawerContent) & ref0(drawerEnd),
      );

  Parser drawerStart() =>
      char(':') &
      word().plusLazy(char(':')).flatten('Drawer start expected') &
      char(':') &
      lineTrailingWhitespace().flatten('Trailing whitespace expected');

  Parser drawerContent() {
    final end = ref0(drawerEnd);
    return (ref0(property) | ref0(nonDrawerElements) | ref1(textRun, end))
        .starLazy(end);
  }

  Parser nonDrawerElements() =>
      nonParagraphElements()..replace(ref0(drawer), noOpFail());

  Parser drawerEnd() =>
      ref0(indent).flatten('Drawer end indent expected') &
      (stringIgnoreCase(':END:') & insignificantWhitespace().starString())
          .flatten('Drawer end expected');

  Parser property() =>
      ref0(indent).flatten('Property indent expected') &
      ref0(propertyKey) &
      ref0(propertyValue) &
      (lineEnd() & ref0(blankLines)).flatten('Trailing whitespace expected');

  Parser propertyKey() =>
      char(':') &
      any()
          .plusLazy(
            char(':') &
                insignificantWhitespace().plusString() &
                lineEnd().not(),
          )
          .flatten('Property name expected') &
      char(':');

  Parser propertyValue() =>
      any().plusLazy(lineEnd()).flatten('Property value expected');

  Parser footnoteReference() =>
      ref0(footnoteReferenceNamed) | ref0(footnoteReferenceInline);

  Parser footnoteReferenceNamed() =>
      string('[fn:') & ref0(footnoteName) & char(']');

  Parser footnoteReferenceInline() =>
      string('[fn:') &
      ref0(footnoteName).optional() &
      char(':') &
      ref0(footnoteDefinition) &
      char(']');

  Parser footnoteName() =>
      pattern('-_A-Za-z0-9').plusString('Footnote name expected');

  Parser footnoteDefinition() => textRun(char(']')).plusLazy(char(']'));

  Parser footnote() => ref0(_footnote).drop1(0);

  Parser _footnote() =>
      lineStart() &
      ref0(footnoteReferenceNamed) &
      ref0(footnoteBody) &
      ref0(blankLines);

  // Org Mode includes in a footnote all elements up to the next footnote or two
  // blank lines. That is hard to express in PEG so for the grammar we limit the
  // footnote scope to the immediate paragraph, and fix up the AST in the
  // parser.
  Parser footnoteBody() {
    final end = endOfInput() |
        lineStart() & ref0(footnoteReferenceNamed) |
        newline().repeatString(2) |
        ref0(nonParagraphElements);
    return ref1(textRun, end).plusLazy(end);
  }

  Parser citation() =>
      string('[cite') &
      ref0(citationStyle).optional() &
      char(':') &
      ref0(citationBody) &
      char(']');

  Parser citationStyle() =>
      char('/') & char(':').neg().plusString('Citation style expected');

  Parser citationBody() => char(']')
      .neg()
      .plusString('Citation body expected')
      .where((val) => val.contains('@'));

  Parser latexBlock() => indented(LatexBlockParser());

  Parser latexInline() =>
      ref2(_latexInline, r'$$', r'$$') |
      ref2(_latexInline, r'\(', r'\)') |
      ref2(_latexInline, r'\[', r'\]') |
      _markup(r'$').drop([0, -1]);

  Parser _latexInline(String start, String end) =>
      string(start) &
      string(end).neg().plusLazy(string(end)).flatten('LaTeX body expected') &
      string(end);
}
