import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/org.dart';
import 'package:petitparser/petitparser.dart';

class OrgParser extends GrammarParser {
  OrgParser() : super(OrgParserDefinition());
}

class OrgParserDefinition extends OrgGrammarDefinition {
  @override
  Parser document() => super.document().map((items) {
        final OrgContent firstContent = items[0];
        final List sections = items[1];
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
        final OrgHeadline headline = items[0];
        final OrgContent content = items[1];
        return OrgSection(headline, content);
      });

  @override
  Parser headline() => super.headline().map((items) {
        final String stars = items[0];
        final String keyword = items[1];
        final String priority = items[2];
        final String rawTitle = items[3];
        final OrgContent title = OrgContentParser().parse(rawTitle).value;
        final List tags = items[4];
        return OrgHeadline(
          stars,
          keyword,
          priority,
          title,
          rawTitle,
          tags?.cast<String>(),
        );
      });

  @override
  Parser priority() => super.priority().pick(1);

  @override
  Parser tags() => super.tags().pick(1);

  @override
  Parser content() =>
      super.content().map((content) => OrgContentParser().parse(content).value);
}

class OrgContentParser extends GrammarParser {
  OrgContentParser() : super(OrgContentParserDefinition());
}

class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  @override
  Parser start() => super
      .start()
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser plainText([Parser limit]) =>
      super.plainText(limit).map((value) => OrgPlainText(value));

  @override
  Parser plainLink() => super.plainLink().map((value) => OrgLink(value, null));

  @override
  Parser regularLink() => super.regularLink().map((values) {
        final location = values[1];
        final description = values.length > 3 ? values[2] : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().pick(1);

  @override
  Parser linkDescription() => super.linkDescription().pick(1);

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

  Parser mapMarkup(Parser parser, OrgStyle style) =>
      parser.flatten('Markup expected').map((value) => OrgMarkup(value, style));

  @override
  Parser affiliatedKeyword() => super.affiliatedKeyword().map((items) {
        final String indent = items[0];
        final String keyword = items[1];
        final String trailing = items[2];
        return OrgMeta(indent, keyword, trailing);
      });

  @override
  Parser fixedWidthArea() => super
      .fixedWidthArea()
      .flatten('Fixed-width area expected')
      .map(_trimLastBlankLine)
      .map((value) => OrgFixedWidthArea(value));

  @override
  Parser namedBlock(String name) => super.namedBlock(name).map((parts) {
        final String indent = parts[0];
        final String header = parts[1];
        final String body = parts[2];
        final String footer = parts[3];
        OrgContentElement bodyContent;
        switch (name) {
          case 'example':
          case 'export':
            bodyContent = OrgMarkup(body, OrgStyle.verbatim);
            break;
          case 'src':
            bodyContent = OrgMarkup(body, OrgStyle.code);
            break;
          default:
            bodyContent = OrgPlainText(body);
        }
        return OrgBlock(indent, header, bodyContent, footer);
      });

  @override
  Parser namedBlockStart(String name) =>
      super.namedBlockStart(name).flatten('Named block "$name" start expected');

  @override
  Parser namedBlockEnd(String name) =>
      super.namedBlockEnd(name).flatten('Named block "$name" end expected');

  @override
  Parser greaterBlock() => super.greaterBlock().map((parts) {
        final String indent = parts[0];
        final String header = parts[1];
        final OrgContent body = parts[2];
        final String footer = parts[3];
        return OrgBlock(indent, header, body, footer);
      });

  @override
  Parser namedGreaterBlockContent(String name) => super
      .namedGreaterBlockContent(name)
      .castList<OrgContentElement>()
      .map((elems) => OrgContent(elems));

  @override
  Parser table() =>
      super.table().castList<OrgTableRow>().map((rows) => OrgTable(rows));

  @override
  Parser tableDotElDivider() => super
      .tableDotElDivider()
      .pick(0)
      .map((indent) => OrgTableDividerRow(indent));

  @override
  Parser tableRowRule() =>
      super.tableRowRule().pick(0).map((item) => OrgTableDividerRow(item));

  @override
  Parser tableRowStandard() => super.tableRowStandard().map((items) {
        final String indent = items[0];
        final List cells = items[2];
        final String trailing = items[3];
        if (trailing.trim().isNotEmpty) {
          cells.add(trailing.trim());
        }
        return OrgTableCellRow(indent, cells.cast<OrgContent>());
      });

  @override
  Parser tableCell() => super.tableCell().pick(1);

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
  Parser keyword() => super.keyword().map((value) => OrgKeyword(value));

  @override
  Parser list() =>
      super.list().castList<OrgListItem>().map((items) => OrgList(items));

  @override
  Parser listItemOrdered() => super.listItemOrdered().map((values) {
        final String indent = values[0];
        final List rest = values[1];
        final String bullet = rest[0];
        final String counterSet = rest[1];
        final String checkBox = rest[2];
        final OrgContent body = rest[3];
        return OrgListOrderedItem(indent, bullet, counterSet, checkBox, body);
      });

  @override
  Parser listItemUnordered() => super.listItemUnordered().map((values) {
        final String indent = values[0];
        final List rest = values[1];
        final String bullet = rest[0];
        final String checkBox = rest[1];
        final String tag = rest[2];
        final OrgContent body = rest[3];
        return OrgListUnorderedItem(indent, bullet, checkBox, tag, body);
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
  Parser listTag() => super.listTag().flatten('List tag expected');
}

String _trimFirstBlankLine(String str) =>
    str.startsWith('\n') ? str.substring(1, str.length) : str;

String _trimLastBlankLine(String str) =>
    str.endsWith('\n') ? str.substring(0, str.length - 1) : str;
