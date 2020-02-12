import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/org.dart';
import 'package:petitparser/petitparser.dart';

class OrgParser extends GrammarParser {
  OrgParser() : super(OrgParserDefinition());
}

class OrgParserDefinition extends OrgGrammarDefinition {
  @override
  Parser document() => super.document().map((items) {
        final String firstContent = items[0];
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
        final String content = items[1];
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
}
