import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('citation', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.citation()).end();
    test('simple', () {
      final result = parser.parse('[cite:@foo]');
      final citation = result.value as OrgCitation;
      expect(citation.leading, '[cite');
      expect(citation.style, isNull);
      expect(citation.delimiter, ':');
      expect(citation.body, '@foo');
      expect(citation.trailing, ']');
    });
    test('with style', () {
      final result = parser.parse('[cite/mystyle:@bar]');
      final citation = result.value as OrgCitation;
      expect(citation.leading, '[cite');
      expect(citation.style?.leading, '/');
      expect(citation.style?.value, 'mystyle');
      expect(citation.delimiter, ':');
      expect(citation.body, '@bar');
      expect(citation.trailing, ']');
    });
    test('multiple keys', () {
      final result = parser.parse('[cite:@foo;@bar]');
      final citation = result.value as OrgCitation;
      expect(citation.leading, '[cite');
      expect(citation.style, isNull);
      expect(citation.delimiter, ':');
      expect(citation.body, '@foo;@bar');
      expect(citation.trailing, ']');
    });
    test('prefix and suffix', () {
      final result = parser.parse('[cite:a ;b @foo c; d]');
      final citation = result.value as OrgCitation;
      expect(citation.leading, '[cite');
      expect(citation.style, isNull);
      expect(citation.delimiter, ':');
      expect(citation.body, 'a ;b @foo c; d');
      expect(citation.trailing, ']');
    });
  });
}
