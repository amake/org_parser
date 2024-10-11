import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('Citations', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.citation()).end();
    test('simple', () {
      final markup = '[cite:@foo]';
      final result = parser.parse(markup);
      final citation = result.value as OrgCitation;
      expect(citation.body, '@foo');
      expect(citation.getKeys(), ['foo']);
      expect(citation.toMarkup(), markup);
    });
    test('multiple keys', () {
      final markup = '[cite:@foo;@bar;@foo]';
      final result = parser.parse(markup);
      final citation = result.value as OrgCitation;
      expect(citation.body, '@foo;@bar;@foo');
      expect(citation.getKeys(), ['foo', 'bar', 'foo']);
      expect(citation.toMarkup(), markup);
    });
    test('prefix and suffix', () {
      final markup = '[cite/style:pre;pre2@bar suff;suff2]';
      final result = parser.parse(markup);
      final citation = result.value as OrgCitation;
      expect(citation.body, 'pre;pre2@bar suff;suff2');
      expect(citation.getKeys(), ['bar']);
      expect(citation.toMarkup(), markup);
    });
    test('invalid', () {
      final markup = '[cite:foo]';
      final result = parser.parse(markup);
      expect(result, isA<Failure>());
    });
  });
}
