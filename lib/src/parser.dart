import 'package:org_parser/org_parser.dart';
import 'package:petitparser/petitparser.dart';

/// The top-level Org parser
final org = OrgParserDefinition().build();

/// Top-level parser definitions
class OrgParserDefinition extends OrgGrammarDefinition {
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
            keyword == null ? null : (value: keyword[0], trailing: keyword[1]),
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
        final value = OrgContent(nodes.cast());
        return [value, title];
      });

  @override
  Parser content() => super
      .content()
      .map((content) => _orgContentParser.parse(content as String).value);
}

/// The content parser. This is not really intended to be used separately; it is
/// used by [org] to parse "content" inside sections.
final _orgContentParser = OrgContentParserDefinition().build();

/// Text run parser. This is not really intended to be used separately; it is
/// used by [org] to parse text content in section headers.
final _textRunParser = (() {
  final definition = OrgContentParserDefinition();
  return definition.buildFrom(definition.textRun().star());
})();

/// Content-level parser definition
class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  @override
  Parser start() =>
      super.start().castList<OrgNode>().map((elems) => OrgContent(elems));

  @override
  Parser paragraph() => super.paragraph().map((items) {
        final indent = items[0] as String;
        final bodyElements = items[1] as List;
        final body = OrgContent(bodyElements.cast());
        return OrgParagraph(indent, body);
      });

  @override
  Parser plainText([Parser? limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value as String));

  @override
  Parser plainLink() =>
      super.plainLink().map((value) => OrgLink(value as String, null));

  @override
  Parser regularLink() => super.regularLink().castList<dynamic>().map((values) {
        final location = values[1] as String;
        final description = values.length > 3 ? values[2] as String? : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().castList<String>().pick(1);

  @override
  Parser linkDescription() =>
      super.linkDescription().castList<String>().pick(1);

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
        final content = values[1] as String;
        final trailing = values[2] as String;
        return OrgMarkup(leading, content, trailing, style);
      });

  @override
  Parser entity() => super.entity().map((values) {
        final leading = values[0] as String;
        final name = values[1] as String;
        final trailing = values[2] as String;
        return OrgEntity(leading, name, trailing);
      });

  @override
  Parser macroReference() => super
      .macroReference()
      .flatten('Macro reference expected')
      .map((value) => OrgMacroReference(value));

  @override
  Parser affiliatedKeyword() => super.affiliatedKeyword().map((items) {
        final indent = items[0] as String;
        final keyword = items[1] as String;
        final trailing = items[2] as String;
        return OrgMeta(indent, keyword, trailing);
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
  Parser namedBlock(String name) => super.namedBlock(name).map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as String;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        OrgNode bodyContent;
        switch (name) {
          case 'example':
          case 'export':
            bodyContent = OrgMarkup.just(content, OrgStyle.verbatim);
            break;
          default:
            bodyContent = OrgPlainText(content);
        }
        return OrgBlock(indent, header, bodyContent, footer, trailing);
      });

  @override
  Parser srcBlock() => super.srcBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final headerToken = body[0] as Token;
        final headerParts = headerToken.value as List;
        final language = headerParts[1] as String?;
        final header = headerToken.input;
        final content = body[1] as String;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        final bodyContent = OrgPlainText(content);
        return OrgSrcBlock(
          language,
          indent,
          header,
          bodyContent,
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
  Parser greaterBlock() => super.greaterBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = body[0] as String;
        final content = body[1] as OrgContent;
        final footer = body[2] as String;
        final trailing = parts[2] as String;
        return OrgBlock(indent, header, content, footer, trailing);
      });

  @override
  Parser namedGreaterBlockContent(String name) => super
      .namedGreaterBlockContent(name)
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser arbitraryGreaterBlock() => super.arbitraryGreaterBlock().map((parts) {
        final indent = parts[0] as String;
        final body = parts[1] as List;
        final header = (body[0] as List).join();
        final content = OrgContent((body[1] as List).cast());
        final footer = (body[2] as List).join();
        final trailing = parts[2] as String;
        return OrgBlock(indent, header, content, footer, trailing);
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
      .pick(0)
      .map((indent) => OrgTableDividerRow(indent));

  @override
  Parser tableRowRule() => super
      .tableRowRule()
      .castList<String>()
      .pick(0)
      .map((item) => OrgTableDividerRow(item));

  @override
  Parser tableRowStandard() => super.tableRowStandard().map((items) {
        final indent = items[0] as String;
        final cells = items[2] as List;
        final trailing = items[3] as String;
        if (trailing.trim().isNotEmpty) {
          cells.add(OrgContent([OrgPlainText(trailing.trim())]));
        }
        return OrgTableCellRow(indent, cells.cast());
      });

  @override
  Parser tableCell() => super.tableCell().castList<dynamic>().pick(1);

  @override
  Parser tableCellContents() => super
      .tableCellContents()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

  @override
  Parser timestamp() => super
      .timestamp()
      .flatten('Timestamp expected')
      .map((value) => OrgTimestamp(value));

  @override
  Parser keyword() =>
      super.keyword().map((value) => OrgKeyword(value as String));

  @override
  Parser planningLine() => super.planningLine().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final keyword = rest[0] as OrgKeyword;
        final bodyElems = rest[1] as List;
        final body = OrgContent(bodyElems.cast());
        final trailing = values[2] as String;
        return OrgPlanningLine(indent, keyword, body, trailing);
      });

  @override
  Parser list() => super.list().map((items) {
        final listItems = items[0] as List;
        final trailing = items[1] as String;
        return OrgList(listItems.cast(), trailing);
      });

  @override
  Parser listItemOrdered() => super.listItemOrdered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final counterSet = rest[1] as String?;
        final checkBox = rest[2] as String?;
        final body = rest[3] as OrgContent?;
        return OrgListOrderedItem(indent, bullet, counterSet, checkBox, body);
      });

  @override
  Parser listItemUnordered() => super.listItemUnordered().map((values) {
        final indent = values[0] as String;
        final rest = values[1] as List;
        final bullet = rest[0] as String;
        final checkBox = rest[1] as String?;
        final tagParts = rest[2] as List?;
        OrgContent? tag;
        String? tagDelimiter;
        if (tagParts != null) {
          final tagList = tagParts[0] as List;
          tag = OrgContent(tagList.cast());
          tagDelimiter = tagParts[1] as String;
        }
        final body = rest[3] as OrgContent?;
        return OrgListUnorderedItem(
          indent,
          bullet,
          checkBox,
          tag,
          tagDelimiter,
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
        return OrgProperty(indent, key, value, trailing);
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
        final delimiter = values[2] as String?;
        final content = values[3] as OrgContent?;
        final trailing = values[4] as String;
        return OrgFootnoteReference(
          leading,
          name,
          delimiter,
          content,
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
        var content = values[1] as OrgContent;
        final trailing = values[2] as String;
        if (trailing.isNotEmpty) {
          content = OrgContent(content.children + [OrgPlainText(trailing)]);
        }
        return OrgFootnote(marker, content);
      });

  @override
  Parser footnoteBody() => super
      .footnoteBody()
      .castList<OrgNode>()
      .map((elems) => OrgContent(elems));

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

/// File link parser
final orgFileLink = OrgFileLinkParserDefinition().build();

/// File link parser definition
class OrgFileLinkParserDefinition extends OrgFileLinkGrammarDefinition {
  @override
  Parser start() => super.start().map((values) {
        final scheme = values[0] as String;
        final body = values[1] as String;
        final extra = values[2] as String?;
        return OrgFileLink(
          scheme.isEmpty ? null : scheme,
          body,
          extra,
        );
      });
}
