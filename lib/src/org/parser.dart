import 'package:org_parser/org_parser.dart';
import 'package:petitparser/petitparser.dart';

/// The top-level Org parser
final org = OrgParserDefinition().build();

/// Top-level parser definitions
class OrgParserDefinition extends OrgGrammarDefinition {
  OrgParserDefinition({super.todoStates, List<String>? radioTargets}) {
    if (radioTargets?.isNotEmpty == true) {
      final definition = OrgContentParserDefinition(radioTargets: radioTargets);
      _contentParser = definition.build();
      _textRunParser = definition.textRunParser;
    }
  }

  late Parser _contentParser = _defaultOrgContentParser;
  late Parser<List<OrgNode>> _textRunParser = _defaultTextRunParser;

  @override
  Parser start() => super.start().map((items) {
        final topContent = items[0] as OrgContent?;
        final sections = items[1] as List;
        return OrgDocument(topContent, List.unmodifiable(sections));
      });

  @override
  Parser document() => super.document().map((items) {
        final firstContent = items[0] as OrgContent?;
        final sections = items[1] as List;
        return [firstContent, _nestSections(sections.cast())];
      });

  List<OrgSection> _nestSections(List<OrgSection> sections) {
    if (sections.length < 2) {
      return sections;
    }
    final result = <OrgSection>[];
    for (var i = 0; i < sections.length; i++) {
      final parent = sections[i];
      final children = sections
          .sublist(i + 1)
          .takeWhile((item) => item.level > parent.level)
          .cast<OrgSection>()
          .toList();
      if (children.isNotEmpty) {
        result.add(parent.copyWith(sections: _nestSections(children)));
        i += children.length;
      } else {
        result.add(parent);
      }
    }
    return result;
  }

  @override
  Parser section() => super.section().map((items) {
        final headline = items[0] as OrgHeadline;
        final content = items[1] as OrgContent?;
        return OrgSection(headline, content);
      });

  @override
  Parser headline() => super.headline().castList<dynamic>().map((items) {
        final [
          stars as List,
          keyword as List?,
          priority as List?,
          title as List?,
          tags as List?,
          trailing as String?
        ] = items;
        return OrgHeadline(
            (value: stars[0], trailing: stars[1]),
            keyword == null
                ? null
                : (
                    value: keyword[0],
                    done: effectiveTodoStates
                        .any((e) => e.done.contains(keyword[0])),
                    trailing: keyword[1]
                  ),
            priority == null
                ? null
                : (
                    leading: priority[0],
                    value: priority[1],
                    trailing: priority[2]
                  ),
            title?[0] as OrgContent?,
            title?[1] as String?,
            tags == null
                ? null
                : (
                    leading: tags[0],
                    values: (tags[1] as SeparatedList).elements.cast(),
                    trailing: tags[2]
                  ),
            trailing);
      });

  @override
  Parser title() => super.title().map((title) {
        final nodes = _textRunParser.parse(title as String).value;
        final value = OrgContent(nodes);
        return [value, title];
      });

  @override
  Parser content() => super
      .content()
      .map((content) => _contentParser.parse(content as String).value);
}

/// The default content parser. This is not really intended to be used
/// separately; it is used by [org] to parse "content" inside sections.
final _defaultOrgContentParser = OrgContentParserDefinition().build();

/// Default text run parser. This is not really intended to be used separately;
/// it is used by [org] to parse text content in section headers.
final _defaultTextRunParser = OrgContentParserDefinition().textRunParser;

// A footnote is terminated by another footnote or by two blank lines.
final _footnoteTerminator = RegExp(r'(?:\r?\n){3}$');

/// Content-level parser definition
class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  OrgContentParserDefinition({super.radioTargets});

  late Parser<List<OrgNode>> textRunParser =
      buildFrom(textRun()).star().castList<OrgNode>().end();

  late Parser<List<OrgNode>> linkDescriptionParser =
      buildFrom(nonLinkTextRun()).star().castList<OrgNode>().end();

  @override
  Parser elements() => super
      .elements()
      .castList<OrgElement>()
      .map((elems) => _fixUpFootnotes(elems))
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  List<OrgElement> _fixUpFootnotes(List<OrgElement> elems) {
    final result = <OrgElement>[];

    for (var i = 0; i < elems.length;) {
      final elem = elems[i++];

      if (elem is! OrgFootnote || _footnoteTerminator.hasMatch(elem.trailing)) {
        result.add(elem);
        continue;
      }

      final toAppend = <OrgNode>[];
      while (i < elems.length &&
          elems[i] is! OrgFootnote &&
          !_footnoteTerminator.hasMatch(elems[i].trailing)) {
        toAppend.add(elems[i++] as OrgNode);
      }

      if (toAppend.isEmpty) {
        result.add(elem);
        continue;
      }

      final merged = elem.copyWith(
        content: OrgContent(
          [
            ...elem.content.children,
            if (elem.trailing.isNotEmpty) OrgPlainText(elem.trailing),
            ...toAppend
          ],
        ),
        trailing: '',
      );
      result.add(merged);
    }
    return result;
  }

  @override
  Parser paragraph() => super.paragraph().map((items) {
        final indent = items[0] as String;
        final bodyElements = items[1] as List;
        final trailing = items[2] as String;
        final body = OrgContent(bodyElements.cast());
        return OrgParagraph(indent, body, trailing);
      });

  @override
  Parser plainText([Parser? limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value as String));

  @override
  Parser plainLink() =>
      super.plainLink().map((value) => OrgPlainLink(value as String));

  @override
  Parser regularLink() => super.regularLink().castList<dynamic>().map((values) {
        final location = values[1] as String;
        final rawDescription = values.length > 3 ? values[2] as String? : null;
        final description = rawDescription == null
            ? null
            : OrgContent(linkDescriptionParser.parse(rawDescription).value);
        return OrgBracketLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().castList<String>().pick(1);

  @override
  Parser linkDescription() =>
      super.linkDescription().castList<String>().pick(1);

  @override
  Parser linkTarget() => super.linkTarget().castList<String>().map((values) {
        final [leading, body, trailing] = values;
        return OrgLinkTarget(leading, body, trailing);
      });

  @override
  Parser radioTarget() => super.radioTarget().castList<String>().map((values) {
        final [leading, body, trailing] = values;
        return OrgRadioTarget(leading, body, trailing);
      });

  @override
  Parser radioLinkImpl(List<String> targets) =>
      super.radioLinkImpl(targets).castList<dynamic>().map((values) {
        final content = values[1] as String;
        return OrgRadioLink(content);
      });

  @override
  Parser inlineSourceBlock() => super.inlineSourceBlock().map((values) {
        final leading = values[0] as String;
        final srcLang = values[1] as String;
        final arguments = values[2] as String?;
        final body = values[3] as String;
        return OrgInlineSrcBlock(leading, srcLang, arguments, body);
      });

  @override
  Parser bold() => mapMarkup(super.bold(), OrgStyle.bold);

  @override
  Parser verbatim() => mapMarkup(super.verbatim(), OrgStyle.verbatim);

  @override
  Parser italic() => mapMarkup(super.italic(), OrgStyle.italic);

  @override
  Parser strikeThrough() =>
      mapMarkup(super.strikeThrough(), OrgStyle.strikeThrough);

  @override
  Parser underline() => mapMarkup(super.underline(), OrgStyle.underline);

  @override
  Parser code() => mapMarkup(super.code(), OrgStyle.code);

  Parser mapMarkup(Parser parser, OrgStyle style) => parser.map((values) {
        final leading = values[0] as String;
        final body = values[1] as String;
        final trailing = values[2] as String;
        final content = switch (style) {
          OrgStyle.bold ||
          OrgStyle.italic ||
          OrgStyle.strikeThrough ||
          OrgStyle.underline =>
            textRunParser.parse(body).value,
          OrgStyle.verbatim || OrgStyle.code => [OrgPlainText(body)],
        };
        return OrgMarkup(leading, OrgContent(content), trailing, style);
      });

  @override
  Parser entity() => super.entity().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String;
        final trailing = values[2] as String;
        return OrgEntity(leading, name, trailing);
      });

  @override
  Parser subscript() => super.subscript().map((values) {
        var leading = values[0] as String;
        var trailing = '';
        var body = values[1] as String;
        if (body.startsWith('{') && body.endsWith('}')) {
          leading += '{';
          trailing += '}';
          body = body.substring(1, body.length - 1);
        }
        final content = textRunParser.parse(body).value;
        return OrgSubscript(leading, OrgContent(content), trailing);
      });

  @override
  Parser superscript() => super.superscript().map((values) {
        var leading = values[0] as String;
        var trailing = '';
        var body = values[1] as String;
        if (body.startsWith('{') && body.endsWith('}')) {
          leading += '{';
          trailing += '}';
          body = body.substring(1, body.length - 1);
        }
        final content = textRunParser.parse(body).value;
        return OrgSuperscript(leading, OrgContent(content), trailing);
      });

  @override
  Parser macroReference() => super
      .macroReference()
      .flatten('Macro reference expected')
      .map((value) => OrgMacroReference(value));

  @override
  Parser affiliatedKeyword() => super.affiliatedKeyword().map((items) {
        final indent = items[0] as String;
        final [String key, String valueStr] = items[1] as List;
        final trailing = items[2] as String;
        final value = valueStr.isNotEmpty
            ? OrgContent(textRunParser.parse(valueStr).value)
            : null;
        return OrgMeta(indent, key, value, trailing);
      });

  @override
  Parser fixedWidthArea() =>
      super.fixedWidthArea().castList<dynamic>().map((items) {
        final body = items[0] as List;
        final firstLine = body[0] as List;
        final indent = firstLine[0] as String;
        final content = firstLine.skip(1).join() +
            body.skip(1).expand((line) => line as List).join();
        final trailing = items[1] as String;
        return OrgFixedWidthArea(indent, content, trailing);
      });

  @override
  Parser localVariables() =>
      super.localVariables().castList<dynamic>().map((items) {
        final [body as List, trailing as String] = items;
        final [
          firstLine as String,
          content as List,
          end as String,
        ] = body;
        return OrgLocalVariables(
          firstLine,
          content.map(
            (line) => (prefix: line[0], content: line[1], suffix: line[2]),
          ),
          end,
          trailing,
        );
      });

  @override
  Parser pgpBlock() => super.pgpBlock().castList<dynamic>().map((items) {
        final [indent as String, block as List, trailing as String] = items;
        final [header, body, footer] = block.cast<String>();
        return OrgPgpBlock(indent, header, body, footer, trailing);
      });

  @override
  Parser comment() => super.comment().castList<dynamic>().map((items) {
        final [
          indent as String,
          start as String,
          content as String,
          trailing as String
        ] = items;
        return OrgComment(indent, start, content, trailing);
      });

  @override
  Parser namedVerbatimBlock(String name) =>
      super.namedVerbatimBlock(name).map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgPlainText;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgBlock(name, indent, header, content, footer, trailing);
      });

  @override
  Parser namedRichBlock(String name) => super.namedRichBlock(name).map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgBlock(name, indent, header, content, footer, trailing);
      });

  @override
  Parser verbatimBlockContent(String name) => super
      .verbatimBlockContent(name)
      .map((value) => OrgPlainText(value as String));

  @override
  Parser srcBlock() => super.srcBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final headerToken = body[0] as Token;
        final headerParts = headerToken.value as List;
        final language = headerParts[1] as String?;
        final header = headerToken.input;
        final content = body[1] as OrgPlainText;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgSrcBlock(
          language,
          indent,
          header,
          content,
          footer,
          trailing,
        );
      });

  @override
  Parser srcBlockStart() => super.srcBlockStart().token();

  @override
  Parser srcBlockLanguageToken() =>
      super.srcBlockLanguageToken().castList<String>().pick(1);

  @override
  Parser namedBlockStart(String name) =>
      super.namedBlockStart(name).flatten('Named block "$name" start expected');

  @override
  Parser namedBlockEnd(String name) =>
      super.namedBlockEnd(name).flatten('Named block "$name" end expected');

  @override
  Parser namedGreaterBlock(String name) =>
      super.namedGreaterBlock(name).map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgBlock(name, indent, header, content, footer, trailing);
      });

  @override
  Parser richBlockContent(String name) => super
      .richBlockContent(name)
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser arbitraryGreaterBlock() => super.arbitraryGreaterBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final name = body[0] as String;
        final header = (body[1] as List).join();
        final content = OrgContent((body[2] as List).cast());
        final footer = (body[3] as List).join();
        final trailing = parts[2] as String;
        return OrgBlock(
            name.toLowerCase(), indent, header, content, footer, trailing);
      });

  @override
  Parser dynamicBlockStart() =>
      super.dynamicBlockStart().flatten('Dynamic block start expected');

  @override
  Parser dynamicBlockContent() => super
      .dynamicBlockContent()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser dynamicBlock() => super.dynamicBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = (body[2] as List).join();
        final trailing = parts[2] as String;
        return OrgDynamicBlock(indent, header, content, footer, trailing);
      });

  @override
  Parser table() => super.table().map((items) {
        final rows = items[0] as List;
        final trailing = items[1] as String;
        return OrgTable(rows.cast(), trailing);
      });

  @override
  Parser tableDotElDivider() => super
      .tableDotElDivider()
      .castList<String>()
      .map((items) => OrgTableDividerRow(items[0], items[1], items[2]));

  @override
  Parser tableRowRule() => super
      .tableRowRule()
      .castList<String>()
      .map((items) => OrgTableDividerRow(items[0], items[1], items[2]));

  @override
  Parser tableRowStandard() => super.tableRowStandard().map((items) {
        final indent = items[0] as String;
        final cells = items[2] as List;
        final trailing = items[3] as String;
        return OrgTableCellRow(indent, cells.cast(), trailing);
      });

  @override
  Parser tableCell() => super.tableCell().map((items) {
        final indent = items[0] as String;
        final content = items[1] as OrgContent;
        final trailing = items[2] as String;
        return OrgTableCell(indent, content, trailing);
      });

  @override
  Parser tableCellContents() => super
      .tableCellContents()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser horizontalRule() =>
      super.horizontalRule().castList<String>().map((value) {
        final [indent, content, trailing] = value;
        return OrgHorizontalRule(indent, content, trailing);
      });

  @override
  Parser timestampDiary() => super
      .timestampDiary()
      .flatten('Diary timestamp expected')
      .map((value) => OrgDiaryTimestamp(value));

  @override
  Parser timestampSimple(bool active) =>
      super.timestampSimple(active).castList<dynamic>().map((value) {
        final [
          prefix as String,
          date as OrgDate,
          time as OrgTime?,
          repeaterOrDelays as List<dynamic>,
          suffix as String
        ] = value;
        return OrgSimpleTimestamp(
            prefix, date, time, repeaterOrDelays.cast(), suffix);
      });

  @override
  Parser timestampDateRange(bool active) =>
      super.timestampDateRange(active).castList<dynamic>().map((value) {
        final [
          start as OrgSimpleTimestamp,
          delimiter as String,
          end as OrgSimpleTimestamp
        ] = value;
        return OrgDateRangeTimestamp(start, delimiter, end);
      });

  @override
  Parser repeaterOrDelay() =>
      super.repeaterOrDelay().flatten('Repeater or delay expected');

  @override
  Parser timestampTimeRange(bool active) =>
      super.timestampTimeRange(active).castList<dynamic>().map((value) {
        final [
          prefix as String,
          date as OrgDate,
          range as List<dynamic>,
          repeaterOrDelays as List<dynamic>,
          suffix as String
        ] = value;
        final [timeStart as OrgTime, _ as String, timeEnd as OrgTime] = range;
        return OrgTimeRangeTimestamp(
          prefix,
          date,
          timeStart,
          timeEnd,
          repeaterOrDelays.cast(),
          suffix,
        );
      });

  @override
  Parser<OrgDate> date() => super.date().castList<String>().map((value) {
        final [year, _, month, _, day, dayName] = value;
        return (year: year, month: month, day: day, dayName: dayName);
      });

  @override
  Parser<OrgTime> time() => super.time().castList<String>().map((value) {
        final [hour, _, minute] = value;
        return (hour: hour, minute: minute);
      });

  @override
  Parser planningKeyword() => super
      .planningKeyword()
      .map((value) => OrgPlanningKeyword(value as String));

  @override
  Parser planningEntry() =>
      super.planningEntry().castList<dynamic>().map((values) {
        final [
          keyword as OrgPlanningKeyword,
          separator as String,
          value as OrgNode
        ] = values;
        return OrgPlanningEntry(keyword, separator, value);
      });

  @override
  Parser list() => super.list().map((items) {
        final listItems = items[0] as List;
        final listTrailing = items[1] as String;
        final (fixedListItems, lastItemtrailing) =
            _fixUpListTrailingSpace(listItems.cast());
        return OrgList(fixedListItems, '$lastItemtrailing$listTrailing');
      });

  (List<OrgListItem>, String) _fixUpListTrailingSpace(List<OrgListItem> items) {
    final lastItem = items.last;
    var trailingSpace = '';
    if (lastItem.body?.children.isNotEmpty == true) {
      final lastChildren = lastItem.body!.children;
      final lastChild = lastChildren.last;
      if (lastChild is OrgPlainText) {
        final m = RegExp(r'\n(\s*)$').firstMatch(lastChild.content);
        if (m != null) {
          items.last = lastItem.parentCopyWith(
            body: OrgContent([
              ...lastChildren.take(lastChildren.length - 1),
              OrgPlainText(lastChild.content.substring(0, m.start + 1)),
            ]),
          );
          trailingSpace = m.group(1)!;
        }
      }
    }
    return (items, trailingSpace);
  }

  @override
  Parser listItemOrdered() => super.listItemOrdered().map((values) {
        final indent = values[0] as String;
        final bullet = values[1] as String;
        final rest = values[2] as List;
        final bulletTrailing = rest[0] as String;
        final counterSet = rest[1] as String?;
        final checkBox = rest[2] as String?;
        final body = rest[3] as OrgContent?;
        return OrgListOrderedItem(
            indent, bullet + bulletTrailing, counterSet, checkBox, body);
      });

  @override
  Parser listItemUnordered() => super.listItemUnordered().map((values) {
        final indent = values[0] as String;
        final bullet = values[1] as String;
        final rest = values[2] as List;
        final bulletTrailing = rest[0] as String;
        final checkBox = rest[1] as String?;
        final tag = rest[2] as List?;
        final body = rest[3] as OrgContent?;
        return OrgListUnorderedItem(
          indent,
          bullet + bulletTrailing,
          checkBox,
          tag == null
              ? null
              : (
                  value: OrgContent((tag[0] as List).cast()),
                  delimiter: tag[1] as String,
                ),
          body,
        );
      });

  @override
  Parser listItemContents() => super
      .listItemContents()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser listOrderedBullet() =>
      super.listOrderedBullet().flatten('Ordered list bullet expected');

  @override
  Parser listCounterSet() =>
      super.listCounterSet().flatten('Counter set expected');

  @override
  Parser listCheckBox() => super.listCheckBox().flatten('Check box expected');

  @override
  Parser statsCookieFraction() =>
      super.statsCookieFraction().castList<String>().map((values) {
        final [leading, numerator, separator, denominator, trailing] = values;
        return OrgStatisticsFractionCookie(
            leading, numerator, separator, denominator, trailing);
      });

  @override
  Parser statsCookiePercent() =>
      super.statsCookiePercent().castList<String>().map((values) {
        final [leading, percentage, suffix, trailing] = values;
        return OrgStatisticsPercentageCookie(
            leading, percentage, suffix, trailing);
      });

  @override
  Parser drawer() => super.drawer().map((values) {
        final indent = values[0] as String;
        final body = values[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = values[2] as String;
        return OrgDrawer(indent, header, content, footer, trailing);
      });

  @override
  Parser drawerStart() => super.drawerStart().flatten('Drawer start expected');

  @override
  Parser drawerContent() => super
      .drawerContent()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser drawerEnd() => super.drawerEnd().flatten('Drawer end expected');

  @override
  Parser property() => super.property().map((values) {
        final indent = values[0] as String;
        final key = values[1] as String;
        final value = values[2] as String;
        final trailing = values[3] as String;
        return OrgProperty(indent, key,
            OrgContent(textRunParser.parse(value).value), trailing);
      });

  @override
  Parser propertyKey() => super.propertyKey().flatten('Property key expected');

  @override
  Parser footnoteReferenceNamed() =>
      super.footnoteReferenceNamed().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String;
        final trailing = values[2] as String;
        return OrgFootnoteReference.named(leading, name, trailing);
      });

  @override
  Parser footnoteReferenceInline() =>
      super.footnoteReferenceInline().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String?;
        final delimiter = values[2] as String;
        final content = values[3] as OrgContent;
        final trailing = values[4] as String;
        return OrgFootnoteReference(
          false,
          leading,
          name,
          (delimiter: delimiter, value: content),
          trailing,
        );
      });

  @override
  Parser footnoteDefinition() => super
      .footnoteDefinition()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser footnote() => super.footnote().map((values) {
        final marker = values[0] as OrgFootnoteReference;
        final content = values[1] as OrgContent;
        final trailing = values[2] as String;
        return OrgFootnote(
            marker.copyWith(isDefinition: true), content, trailing);
      });

  @override
  Parser footnoteBody() => super
      .footnoteBody()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser citation() => super.citation().map((values) {
        final leading = values[0] as String;
        final style = values[1] as List?;
        final delimiter = values[2] as String;
        final body = values[3] as String;
        final trailing = values[4] as String;
        return OrgCitation(
            leading,
            style == null ? null : (leading: style[0], value: style[1]),
            delimiter,
            body,
            trailing);
      });

  @override
  Parser latexBlock() => super.latexBlock().map((values) {
        final leading = values[0] as String;
        final body = values[1] as List;
        final blockStart = body[0] as List;
        final begin = blockStart.join('');
        final environment = blockStart[1] as String;
        final content = body[1] as String;
        final end = body[2] as String;
        final trailing = values[2] as String;
        return OrgLatexBlock(
          environment,
          leading,
          begin,
          content,
          end,
          trailing,
        );
      });

  @override
  Parser latexInline() => super.latexInline().map((values) {
        final leading = values[0] as String;
        final body = values[1] as String;
        final trailing = values[2] as String;
        return OrgLatexInline(leading, body, trailing);
      });
}
