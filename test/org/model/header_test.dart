import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('header', () {
    final definition = OrgParserDefinition();
    final parser = definition.buildFrom(definition.headline()).end();
    test('full', () {
      final markup = '** TODO [#A] Title foo bar :biz:baz:';
      final result = parser.parse(markup);
      final headline = result.value as OrgHeadline;
      expect(headline.contains('Title foo'), isTrue);
      expect(headline.toMarkup(), markup);
    });
    test('empty', () {
      final markup = '* ';
      final result = parser.parse(markup);
      final headline = result.value as OrgHeadline;
      expect(headline.toMarkup(), markup);
    });
  });
}
