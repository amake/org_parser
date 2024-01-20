import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/query/query.dart';
import 'package:test/test.dart';

final _sectionParser = (() {
  final definition = OrgParserDefinition();
  return definition.buildFrom(definition.section());
})();

Matcher acceptsSection(String sectionMarkup) =>
    _QueryMatcher(sectionMarkup, true);
Matcher rejectsSection(String sectionMarkup) =>
    _QueryMatcher(sectionMarkup, false);

class _QueryMatcher extends Matcher {
  _QueryMatcher(
    String sectionMarkup,
    this.expected,
  ) : section = _sectionParser.parse(sectionMarkup).value as OrgSection;

  final OrgSection section;
  final bool expected;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! OrgQueryMatcher) return false;

    return item.matches(section) == expected;
  }

  @override
  Description describe(Description description) => description.add(expected
      ? 'The query accepts the section'
      : 'The query rejects the section');
}
