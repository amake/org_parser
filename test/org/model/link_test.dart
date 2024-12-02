import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.link()).end();
    test('brackets in location', () {
      final markup = '[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]';
      final result = parser.parse(markup);
      final link = result.value as OrgBracketLink;
      expect(link.contains('what?'), isTrue);
      expect(link.contains('あ'), isFalse);
      expect(link.toMarkup(), markup);
    });
    test('link with search option', () {
      final markup = '[[foo::1][bar]]';
      final result = parser.parse(markup);
      final link = result.value as OrgBracketLink;
      expect(link.contains('foo'), isTrue);
      expect(link.contains('あ'), isFalse);
      expect(link.toMarkup(), markup);
    });
    test('quotes in search option', () {
      final markup = r'[[foo::"\[1\]"][bar]]';
      final result = parser.parse(markup);
      final link = result.value as OrgBracketLink;
      expect(link.contains('foo'), isTrue);
      expect(link.contains('あ'), isFalse);
      expect(link.toMarkup(), markup);
    });
    test('no description', () {
      final markup = '[[foo::1]]';
      final result = parser.parse(markup);
      final link = result.value as OrgBracketLink;
      expect(link.contains('foo'), isTrue);
      expect(link.contains('あ'), isFalse);
      expect(link.toMarkup(), markup);
    });
    test('plain link', () {
      final markup = 'http://example.com';
      final result = parser.parse(markup);
      final link = result.value as OrgLink;
      expect(link.contains('example'), isTrue);
      expect(link.contains('あ'), isFalse);
      expect(link.toMarkup(), markup);
    });
  });
}
