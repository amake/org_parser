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
        final OrgContent title = OrgContentParser().parse(items[3]).value;
        final List tags = items[4];
        return OrgHeadline(
            stars, keyword, priority, title, tags?.cast<String>());
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
  Parser start() => super.start().map(_toOrgContent);

  OrgContent _toOrgContent(Object values) {
    final List elems = values;
    return OrgContent(elems.cast<OrgContentElement>());
  }

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
  Parser linkPartBody() =>
      super.linkPartBody().flatten('Link part body expected');

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
  Parser meta() => super.meta().map((value) => OrgMeta(value));

  @override
  Parser codeLine() => mapMarkup(super.codeLine(), OrgStyle.code);

  @override
  Parser namedBlock(String name) => super.namedBlock(name).map((parts) {
        final String header = parts[0];
        final String body = parts[1];
        final String footer = parts[2];
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
        return OrgBlock(header, bodyContent, footer);
      });

  @override
  Parser namedBlockStart(String name) => super
      .namedBlockStart(name)
      .flatten('Named block "$name" start expected')
      .map(_trimLastBlankLine);

  String _trimLastBlankLine(String str) =>
      str.endsWith('\n') ? str.substring(0, str.length - 1) : str;

  @override
  Parser namedBlockEnd(String name) => super
      .namedBlockEnd(name)
      .flatten('Named block "$name" end expected')
      .map(_trimFirstBlankLine);

  String _trimFirstBlankLine(String str) =>
      str.startsWith('\n') ? str.substring(1, str.length) : str;

  @override
  Parser greaterBlock() => super.greaterBlock().map((parts) {
        final String header = parts[0];
        final OrgContent body = parts[1];
        final String footer = parts[2];
        return OrgBlock(header, body, footer);
      });

  @override
  Parser namedGreaterBlockContent(String name) =>
      super.namedGreaterBlockContent(name).map(_toOrgContent);

  @override
  Parser table() => super.table().map((items) {
        final List rows = items;
        return OrgTable(rows.cast<OrgTableRow>());
      });

  @override
  Parser tableDotElDivider() => super.tableDotElDivider().map((items) {
        final String indent = items[0];
        return OrgTableDividerRow(indent);
      });

  @override
  Parser tableRowRule() => super.tableRowRule().map((items) {
        final String indent = items[0];
        return OrgTableDividerRow(indent);
      });

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
  Parser tableCellContents() => super.tableCellContents().map(_toOrgContent);

  @override
  Parser timestamp() => super
      .timestamp()
      .flatten('Timestamp expected')
      .map((value) => OrgTimestamp(value));
}
