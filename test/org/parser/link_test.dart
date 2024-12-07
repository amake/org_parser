import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.link()).end();
    test('brackets in location', () {
      final result =
          parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      final link = result.value as OrgBracketLink;
      expect(link.location, '*[wtf] what?');
      expect(link.description!.children.single.toMarkup(), '[lots][of][boxes]');
    });
    test('link with search option', () {
      final result = parser.parse('[[foo::1][bar]]');
      final link = result.value as OrgBracketLink;
      expect(link.description!.children.single.toMarkup(), 'bar');
      expect(link.location, 'foo::1');
    });
    test('quotes in search option', () {
      final result = parser.parse(r'[[foo::"\[1\]"][bar]]');
      final link = result.value as OrgBracketLink;
      expect(link.description!.children.single.toMarkup(), 'bar');
      expect(link.location, 'foo::"[1]"');
    });
    test('no description', () {
      final result = parser.parse('[[foo::1]]');
      final link = result.value as OrgBracketLink;
      expect(link.description, isNull);
      expect(link.location, 'foo::1');
    });
    test('plain link', () {
      final result = parser.parse('http://example.com');
      final link = result.value as OrgLink;
      expect(link.location, 'http://example.com');
    });
  });
}
