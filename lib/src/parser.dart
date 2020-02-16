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
      final OrgSection parent = sections[i];
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
        final String title = items[3];
        final List<String> tags = items[4];
        return OrgHeadline(stars, keyword, priority, title, tags);
      });

  @override
  Parser content() =>
      super.content().map((content) => OrgContentParser().parse(content).value);
}

class OrgContentParser extends GrammarParser {
  OrgContentParser() : super(OrgContentParserDefinition());
}

class OrgContentParserDefinition extends OrgContentGrammarDefinition {
  @override
  Parser start() => super.start().map((values) {
        final elems = values as List;
        return OrgContent(elems.cast<OrgContent>());
      });

  @override
  Parser plainText() => super.plainText().map((value) => OrgPlainText(value));

  @override
  Parser link() => super.link().map((values) {
        final location = values[1];
        final description = values.length > 3 ? values[2] : null;
        return OrgLink(location, description);
      });

  @override
  Parser linkPart() => super.linkPart().pick(1);

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
      parser.flatten().map((value) => OrgMarkup(value, style));
}
