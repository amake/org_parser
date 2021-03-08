import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/org.dart';
import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';

class OrgParser extends GrammarParser {
  OrgParser() : super(OrgParserDefinition());
}

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
        return [firstContent, _nestSections(sections.cast<OrgSection>())];
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
          .takeWhile((item) => item is OrgSection && item.level > parent.level)
          .cast<OrgSection>()
          .toList();
      if (children.isNotEmpty) {
        result.add(parent.copyWith(children: _nestSections(children)));
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
  Parser headline() => super.headline().map((items) {
        final stars = items[0] as String;
        final keyword = items[1] as String?;
        final priority = items[2] as String?;
        final title = items[3] as Token?;
        final tags = items[4] as List?;
        return OrgHeadline(
          stars,
          keyword,
          priority,
          title?.value as OrgContent,
          title?.input,
          tags?.cast<String>(),
        );
      });

  @override
  Parser title() {
    final limit = ref(tags) | lineEnd();
    return OrgContentParser.textRun(limit)
        .plusLazy(limit)
        .castList<OrgContentElement>()
        .map((items) => OrgContent(items))
        .token();
  }

  @override
  Parser priority() => super.priority().flatten('Priority expected');

  @override
  Parser tags() => super.tags().castList().pick(1);

  @override
  Parser content() => super
      .content()
      .map((content) => _orgContentParser.parse(content as String).value);
}

final _orgContentParser = OrgContentParser();

class OrgContentParser extends GrammarParser {
  OrgContentParser() : super(OrgContentParserDefinition());

  static Parser textRun([Parser? limit]) {
    final definition = OrgContentParserDefinition();
    final args = limit == null ? const <Object>[] : [limit];
    return definition.build(start: definition.textRun, arguments: args);
  }
}

class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  @override
  Parser start() => super
      .start()
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser paragraph() => super.paragraph().map((items) {
        final indent = items[0] as String;
        final bodyElements = items[1] as List;
        final body = OrgContent(bodyElements.cast<OrgContentElement>());
        return OrgParagraph(indent, body);
      });

  @override
  Parser plainText([Parser? limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value as String));

  @override
  Parser plainLink() =>
      super.plainLink().map((value) => OrgLink(value as String, null));

  @override
  Parser regularLink() => super.regularLink().castList().map((values) {
        final location = values[1] as String;
        final description = values.length > 3 ? values[2] as String? : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().castList().pick(1);

  @override
  Parser linkDescription() => super.linkDescription().castList().pick(1);

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
  Parser fixedWidthArea() => super.fixedWidthArea().castList().map((items) {
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
        OrgContentElement bodyContent;
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
        final language = headerParts[1] as String;
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
      super.srcBlockLanguageToken().castList().pick(1);

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
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser table() => super.table().map((items) {
        final rows = items[0] as List;
        final trailing = items[1] as String;
        return OrgTable(rows.cast<OrgTableRow>(), trailing);
      });

  @override
  Parser tableDotElDivider() => super
      .tableDotElDivider()
      .castList()
      .pick(0)
      .map((indent) => OrgTableDividerRow(indent as String));

  @override
  Parser tableRowRule() => super
      .tableRowRule()
      .castList()
      .pick(0)
      .map((item) => OrgTableDividerRow(item as String));

  @override
  Parser tableRowStandard() => super.tableRowStandard().map((items) {
        final indent = items[0] as String;
        final cells = items[2] as List;
        final trailing = items[3] as String;
        if (trailing.trim().isNotEmpty) {
          cells.add(OrgContent([OrgPlainText(trailing.trim())]));
        }
        return OrgTableCellRow(indent, cells.cast<OrgContent>());
      });

  @override
  Parser tableCell() => super.tableCell().castList().pick(1);

  @override
  Parser tableCellContents() => super
      .tableCellContents()
      .castList<OrgContentElement>()
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
        final body = OrgContent(bodyElems.cast<OrgContentElement>());
        final trailing = values[2] as String;
        return OrgPlanningLine(indent, keyword, body, trailing);
      });

  @override
  Parser list() => super.list().map((items) {
        final listItems = items[0] as List;
        final trailing = items[1] as String;
        return OrgList(listItems.cast<OrgListItem>(), trailing);
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
          tag = OrgContent(tagList.cast<OrgContentElement>());
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
      .castList<OrgContentElement>()
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
      .castList<OrgContentElement>()
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
      .castList<OrgContentElement>()
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
      .castList<OrgContentElement>()
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
