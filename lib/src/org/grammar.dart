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
          .flatten(message: 'Priority trailing expected');

  Parser title() {
    final limit = ref0(tags) | lineEnd();
    return newline().neg().plusLazy(limit).flatten(message: 'Title expected');
  }

  Parser tags() => (was(char(' ')) &
          string(':') &
          ref0(tag).plusSeparated(char(':')) &
          char(':') &
          lineEnd().and())
      .drop1(0);

  Parser tag() =>
      (alnum() | anyOf('_@#%')).plus().flatten(message: 'Tags expected');

  Parser content() => ref0(_content).flatten(message: 'Content expected');

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
  Parser start() => ref0(elements).end();

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
      ref0(drawer) |
      ref0(footnote) |
      ref0(localVariables) |
      ref0(pgpBlock) |
      ref0(comment) |
      ref0(paragraph);

  Parser elements() => ref0(element).star();

  Parser nonBlockElement() => element()
    ..replace(ref0(block), noOpFail())
    ..replace(ref0(greaterBlock), noOpFail())
    ..replace(ref0(arbitraryGreaterBlock), noOpFail());

  Parser paragraph() =>
      ref0(indent).flatten(message: 'Paragraph indent expected') &
      ref1(textRun, ref0(paragraphEnd)).plusLazy(ref0(paragraphEnd)) &
      ref0(blankLines);

  Parser nonParagraphElement() =>
      element()..replace(ref0(paragraph), noOpFail());

  Parser paragraphEnd() =>
      endOfInput() | newline().repeatString(2, 2) | ref0(nonParagraphElement);

  Parser textRun([Parser? limit]) => ref0(object) | ref1(plainText, limit);

  Parser nonLinkTextRun([Parser? limit]) =>
      ref0(nonLinkObjects) | ref1(plainText, limit);

  Parser object() =>
      ref0(link) |
      ref0(linkTarget) |
      ref0(radioTarget) |
      ref0(radioLink) |
      ref0(inlineSourceBlock) |
      ref0(markups) |
      ref0(entity) |
      ref0(subscript) |
      ref0(superscript) |
      ref0(timestamp) |
      ref0(planningEntry) |
      ref0(planningKeyword) |
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
    return any().plusLazy(fullLimit).flatten(message: 'Plain text expected');
  }

  Parser link() => ref0(regularLink) | ref0(plainLink);

  Parser plainLink() =>
      ref0(_plainLink).flatten(message: 'Plain link expected');

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
      ref0(linkTargetContent).flatten(message: 'Target content expected') &
      string('>>');

  Parser linkTargetContent() =>
      ref0(linkTargetBorder).and() &
      anyOf('<>\n\r').neg().starLazy(ref0(linkTargetBorder) & string('>>')) &
      ref0(linkTargetBorder);

  Parser linkTargetBorder() => anyOf('<>\n\r \t').neg();

  Parser radioTarget() =>
      string('<<<') &
      ref0(linkTargetContent).flatten(message: 'Target content expected') &
      string('>>>');

  Parser radioLink() => radioTargets?.isNotEmpty == true
      ? ref1(radioLinkImpl, radioTargets!)
      : failure();

  Parser radioLinkImpl(List<String> targets) =>
      ref0(radioLinkBefore) &
      targets.map((t) => string(t, ignoreCase: true)).toChoiceParser() &
      ref0(radioLinkAfter);

  Parser radioLinkBefore() =>
      lineStart() | was(alnum().neg() | lineBreakable());

  Parser radioLinkAfter() =>
      lineEnd().and() | alnum().not() | lineBreakable().and();

  Parser inlineSourceBlock() =>
      string('src_') &
      ref0(inlineSourceLanguage) &
      ref0(inlineSourceArguments).optional() &
      ref0(inlineSourceBody);

  // TODO(aaron): Do we need to include \r? It's not in the original regex.
  Parser inlineSourceLanguage() => anyOf(' \t\n[{').neg().plusString();

  Parser inlineSourceArguments() =>
      (char('[') & any().starLazy(char(']')) & char(']'))
          .flatten(message: 'Arguments expected');

  Parser inlineSourceBody() =>
      (char('{') & any().starLazy(char('}')) & char('}'))
          .flatten(message: 'Body expected');

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
      ref1(markupContents, marker).flatten(message: 'Markup content expected') &
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
      ref0(entityBody).flatten(message: 'Entity body expected') &
      ref0(entityEnd).flatten(message: 'Entity end expected');

  Parser entityBody() =>
      string('there4') |
      (string('sup') & anyOf('123')) |
      (string('frac') & anyOf('13') & anyOf('24')) |
      pattern('a-zA-Z').plus();

  Parser entityEnd() => lineEnd().and() | string('{}') | alpha().not();

  Parser subscript() => (was(whitespace().neg()) &
          char('_') &
          ref0(subSuperscriptBody).flatten(message: 'Subscript body expected'))
      .drop1(0);

  Parser superscript() => (was(whitespace().neg()) &
          char('^') &
          ref0(subSuperscriptBody)
              .flatten(message: 'Superscript body expected'))
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
      ref0(macroReferenceKey).flatten(message: 'Macro reference key expected') &
      // TODO(aaron): Actually parse arguments
      ref0(macroReferenceArgs)
          .optional()
          .flatten(message: 'Macro reference args expected') &
      string('}}}');

  // See `org-element-macro-parser'
  Parser macroReferenceKey() =>
      pattern('a-zA-Z') & pattern('-A-Za-z0-9_').plusString();

  Parser macroReferenceArgs() =>
      char('(') & any().starLazy(char(')')) & char(')');

  Parser affiliatedKeyword() => indented(ref0(affiliatedKeywordKey)
          .flatten(message: 'Affiliated keyword body expected') &
      ref0(affiliatedKeywordValue));

  Parser affiliatedKeywordKey() =>
      string('#+') & whitespace().neg().starLazy(char(':')) & char(':');

  Parser affiliatedKeywordValue() => any()
      .starLazy(lineEnd())
      .flatten(message: 'Affiliated keyword value expected');

  Parser fixedWidthArea() => ref0(fixedWidthLine).plus() & ref0(blankLines);

  Parser fixedWidthLine() =>
      ref0(indent).flatten(message: 'Fixed-width line indent expected') &
      string(': ') &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  Parser localVariables() => localVariablesParser() & ref0(blankLines);

  Parser pgpBlock() =>
      indented(ref0(pgpBlockStart) & ref0(pgpBlockBody) & ref0(pgpBlockEnd));

  Parser pgpBlockStart() => string('-----BEGIN PGP MESSAGE-----');

  Parser pgpBlockBody() => any()
      .starLazy(ref0(pgpBlockEnd))
      .flatten(message: 'PGP block body expected');

  Parser pgpBlockEnd() => string('-----END PGP MESSAGE-----');

  Parser comment() =>
      ref0(indent).flatten(message: 'Comment indent expected') &
      (char('#') & anyOf(' \t')).flatten(message: 'Comment start expected') &
      newline().neg().starString(message: 'Comment content expected') &
      ref0(blankLines);

  Parser block() =>
      // Comment is not exported so it can have arbitrary content
      ref1(namedGreaterBlock, 'comment') |
      ref1(namedVerbatimBlock, 'example') |
      ref1(namedVerbatimBlock, 'export') |
      ref0(srcBlock) |
      // Verse is stylized in buffer, but exported as whitespace-verbatim plain
      // text
      ref1(namedRichBlock, 'verse') |
      ref0(dynamicBlock);

  Parser srcBlock() => indented(
        ref0(srcBlockStart) &
            ref1(verbatimBlockContent, 'src') &
            ref1(namedBlockEnd, 'src'),
      );

  Parser namedVerbatimBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            ref1(verbatimBlockContent, name) &
            ref1(namedBlockEnd, name),
      );

  Parser namedRichBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            ref1(richBlockContent, name) &
            ref1(namedBlockEnd, name),
      );

  Parser richBlockContent(String name) {
    final end = ref1(namedBlockEnd, name);
    return ref1(textRun, end).starLazy(end);
  }

  Parser srcBlockStart() =>
      (string('#+begin_src', ignoreCase: true) & whitespace().neg().not())
          .flatten(message: 'Src block start expected') &
      ref0(srcBlockLanguageToken).optional() &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  Parser srcBlockLanguageToken() =>
      insignificantWhitespace()
          .plusString(message: 'Separating whitespace expected') &
      whitespace().neg().plusString(message: 'Language token expected');

  Parser namedBlockStart(String name) =>
      string('#+begin_$name', ignoreCase: true) &
      (whitespace().neg().not() & ref0(lineTrailing))
          .flatten(message: 'Trailing line content expected');

  Parser verbatimBlockContent(String name) => ref1(namedBlockEnd, name)
      .neg()
      .starString(message: 'Named block content expected');

  Parser namedBlockEnd(String name) =>
      ref0(indent).flatten(message: 'Block end indent expected') &
      (string('#+end_$name', ignoreCase: true) & whitespace().neg().not())
          .flatten(message: 'Block end expected');

  Parser greaterBlock() =>
      ref1(namedGreaterBlock, 'quote') | ref1(namedGreaterBlock, 'center');

  Parser namedGreaterBlock(String name) => indented(
        ref1(namedBlockStart, name) &
            greaterBlockContent(name) &
            ref1(namedBlockEnd, name),
      );

  Parser greaterBlockContent(String name) {
    final end = ref1(namedBlockEnd, name);
    return any()
        .starLazy(end)
        .flatten(message: 'Greater block content expected');
  }

  Parser arbitraryGreaterBlock() =>
      indented(blockParser(ref0(nonBlockElement).star()));

  Parser dynamicBlock() => indented(ref0(dynamicBlockStart) &
      ref0(dynamicBlockContent) &
      ref0(dynamicBlockEnd));

  Parser dynamicBlockStart() =>
      string('#+begin:', ignoreCase: true) &
      // Dynamic block requires a function name. Not really the same as
      // srcBlockLanguageToken, but close enough
      ref0(srcBlockLanguageToken) &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  Parser dynamicBlockContent() {
    final end = ref0(dynamicBlockEnd);
    return any()
        .starLazy(end)
        .flatten(message: 'Dynamic block content expected');
  }

  Parser dynamicBlockEnd() =>
      ref0(indent).flatten(message: 'Block end indent expected') &
      string('#+end:', ignoreCase: true);

  Parser indent() => lineStart() & insignificantWhitespace().starString();

  Parser indented(Parser parser) =>
      ref0(indent).flatten(message: 'Indent expected') &
      parser &
      (ref0(lineTrailing) & ref0(blankLines))
          .flatten(message: 'Trailing line content expected');

  Parser blankLines() => newline().starString(message: 'Blank lines expected');

  Parser lineTrailing() => any().starLazy(lineEnd()) & lineEnd();

  Parser lineTrailingWhitespace() =>
      insignificantWhitespace().starLazy(lineEnd()) & lineEnd();

  Parser table() => ref0(tableLine).plus() & blankLines();

  Parser tableLine() => ref0(tableRow) | ref0(tableDotElDivider);

  Parser tableRow() => ref0(tableRowRule) | ref0(tableRowStandard);

  Parser tableRowStandard() =>
      ref0(indent).flatten(message: 'Table row indent expected') &
      char('|') &
      ref0(tableCell).star() &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  Parser tableCell() =>
      ref0(tableCellLeading) &
      ref0(tableCellContents) &
      ref0(tableCellTrailing)
          .flatten(message: 'Cell trailing content expected');

  Parser tableCellLeading() => char(' ').starString();

  Parser tableCellTrailing() => char(' ').starString() & char('|');

  Parser tableCellContents() {
    final end = ref0(tableCellTrailing) | lineEnd();
    return any().starLazy(end).flatten(message: 'Table cell content expected');
  }

  Parser tableRowRule() =>
      ref0(indent).flatten(message: 'Table row rule indent expected') &
      (string('|-') & anyOf('-+').starString() & char('|'))
          .flatten(message: 'Trailing line content expected') &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  // This grammar can actually be customized in table.el; see
  // `table-cell-*-char(s)`. See `table-recognize` for where they are combined
  // for parsing purposes.
  Parser tableDotElDivider() =>
      ref0(indent).flatten(message: 'Table.el divider indent expected') &
      // At least three characters required
      (string('+-') & anyOf('+-').plusString())
          .flatten(message: 'Table divider expected') &
      ref0(lineTrailing).flatten(message: 'Trailing line content expected');

  Parser horizontalRule() =>
      ref0(indent).flatten(message: 'Indent expected') &
      char('-').repeatString(5, unbounded) &
      (ref0(lineTrailingWhitespace) & ref0(blankLines))
          .flatten(message: 'Trailing line content expected');

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
      (anyOf(delimiters) | whitespace())
          .neg()
          .plusString(message: 'Expected atom');

  Parser sexpList([String delimiters = '()']) =>
      char(delimiters[0]) &
      ref1(sexp, delimiters).trim().star() &
      char(delimiters[1]);

  Parser timestampSimple(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      ref0(time).trim().optional() &
      ref0(repeaterOrDelays) &
      (active ? char('>') : char(']'));

  Parser timestampRange(bool active) =>
      ref1(timestampTimeRange, active) | ref1(timestampDateRange, active);

  Parser timestampTimeRange(bool active) =>
      (active ? char('<') : char('[')) &
      ref0(date) &
      (ref0(time) & char('-') & ref0(time)).trim() &
      ref0(repeaterOrDelays) &
      (active ? char('>') : char(']'));

  Parser timestampDateRange(bool active) =>
      ref1(timestampSimple, active) &
      char('-').repeatString(1, 3, message: 'Expected timestamp separator') &
      ref1(timestampSimple, active);

  Parser date() =>
      ref0(year) &
      char('-') &
      ref0(month) &
      char('-') &
      ref0(day) &
      dayName().trim().optional();

  Parser year() => digit().timesString(4, message: 'Expected year');

  Parser month() => digit().timesString(2, message: 'Expected month');

  Parser day() => digit().timesString(2, message: 'Expected day');

  Parser dayName() => (whitespace() | anyOf('+-]>\n') | digit())
      .neg()
      .plusString(message: 'Expected day name');

  Parser time() => ref0(hours) & char(':') & ref0(minutes);

  Parser hours() => digit().repeatString(1, 2, message: 'Expected hours');

  Parser minutes() => digit().timesString(2, message: 'Expected minutes');

  // TODO(aaron): Figure out if the spec is actually more restrictive than this.
  //
  // Namely, it appears that the only valid use cases are:
  //
  // - None
  // - One of Repeater, Min/max Repeater, or Delay
  // - Repeater followed by Delay
  //
  // We can be lenient here for the time being because we are not trying to
  // validate the content.
  Parser repeaterOrDelays() => ref0(repeaterOrDelay).trim().repeat(0, 2);

  Parser repeaterOrDelay() =>
      ref0(minMaxRepeater) | ref0(repeater) | ref0(delay);

  Parser minMaxRepeater() =>
      ref0(repeaterMark) &
      digit().plusString(message: 'Expected number') &
      ref0(repeatOrDelayUnit) &
      char('/') &
      digit().plusString(message: 'Expected number') &
      ref0(repeatOrDelayUnit);

  Parser repeater() =>
      ref0(repeaterMark) &
      digit().plusString(message: 'Expected number') &
      ref0(repeatOrDelayUnit);

  Parser repeaterMark() => string('++') | string('.+') | char('+');

  Parser delay() =>
      ref0(delayMark) &
      digit().plusString(message: 'Expected number') &
      ref0(repeatOrDelayUnit);

  Parser delayMark() => string('--') | char('-');

  Parser repeatOrDelayUnit() => anyOf('hdwmy');

  Parser planningEntry() =>
      planningKeyword() & insignificantWhitespace().starString() & timestamp();

  Parser planningKeyword() =>
      string('SCHEDULED:') |
      string('DEADLINE:') |
      string('CLOCK:') |
      string('CLOSED:');

  Parser list() => ref0(listItem).plus() & ref0(blankLines);

  Parser listItem() => ref0(listItemUnordered) | ref0(listItemOrdered);

  Parser listItemUnordered() =>
      ref0(listItemUnorderedIndent).flatten(message: 'indent expected') &
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
        end.flatten(message: 'List tag end expected');
  }

  Parser listItemOrdered() =>
      ref0(listItemOrderedIndent).flatten(message: 'indent expected') &
      ref0(listOrderedBullet).flatten(message: 'Ordered bullet expected') &
      indentedRegion(
        parser: char(' ').starString() &
            ref0(listCounterSet).trim(char(' ')).optional() &
            ref0(listCheckBox).trim(char(' ')).optional() &
            ref0(listItemContents),
      );

  Parser listItemOrderedIndent() =>
      ref0(indent) & (ref0(listOrderedBullet) & char(' ')).and();

  Parser listOrderedBullet() =>
      (digit().plusString(message: 'Bullet number expected') | letter()) &
      anyOf('.)');

  Parser listCounterSet() =>
      string('[@') &
      digit().plusString(message: 'Counter set number expected') &
      char(']');

  Parser listCheckBox() => char('[') & anyOf(' -X') & char(']');

  Parser listItemContents() {
    final end =
        ref0(listItemAnyStart) | ref0(nonParagraphElement) | endOfInput();
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
      (anyOf('_-') | word())
          .plusLazy(char(':'))
          .flatten(message: 'Drawer start expected') &
      char(':') &
      lineTrailingWhitespace().flatten(message: 'Trailing whitespace expected');

  Parser drawerContent() {
    final end = ref0(drawerEnd);
    return (ref0(property) | ref0(nonDrawerElements) | ref1(textRun, end))
        .starLazy(end);
  }

  Parser nonDrawerElements() =>
      nonParagraphElement()..replace(ref0(drawer), noOpFail());

  Parser drawerEnd() =>
      ref0(indent).flatten(message: 'Drawer end indent expected') &
      (string(':END:', ignoreCase: true) &
              insignificantWhitespace().starString())
          .flatten(message: 'Drawer end expected');

  Parser property() =>
      ref0(indent).flatten(message: 'Property indent expected') &
      ref0(propertyKey) &
      ref0(propertyValue) &
      (lineEnd() & ref0(blankLines))
          .flatten(message: 'Trailing whitespace expected');

  Parser propertyKey() =>
      char(':') &
      (whitespace() | char(':'))
          .neg()
          .plusString(message: 'Property name expected') &
      char(':');

  Parser propertyValue() => (insignificantWhitespace().plus() &
          whitespace().neg() &
          any().starLazy(lineEnd()))
      .flatten(message: 'Property value expected');

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
      pattern('-_A-Za-z0-9').plusString(message: 'Footnote name expected');

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
        newline().repeatString(2, 2) |
        ref0(nonParagraphElement);
    return ref1(textRun, end).plusLazy(end);
  }

  Parser citation() =>
      string('[cite') &
      ref0(citationStyle).optional() &
      char(':') &
      ref0(citationBody) &
      char(']');

  Parser citationStyle() =>
      char('/') &
      char(':').neg().plusString(message: 'Citation style expected');

  Parser citationBody() => char(']')
      .neg()
      .plusString(message: 'Citation body expected')
      .where((val) => val.contains('@'));

  Parser latexBlock() => indented(LatexBlockParser());

  Parser latexInline() =>
      ref2(_latexInline, r'$$', r'$$') |
      ref2(_latexInline, r'\(', r'\)') |
      ref2(_latexInline, r'\[', r'\]') |
      _markup(r'$').drop([0, -1]);

  Parser _latexInline(String start, String end) =>
      string(start) &
      string(end)
          .neg()
          .plusLazy(string(end))
          .flatten(message: 'LaTeX body expected') &
      string(end);
}
