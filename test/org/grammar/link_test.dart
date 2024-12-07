import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.link()).end();
    test('with description', () {
      final result = parser.parse('[[http://example.com][example]]');
      expect(result.value, [
        '[',
        ['[', 'http://example.com', ']'],
        ['[', 'example', ']'],
        ']'
      ]);
    });
    test('brackets in location', () {
      final result =
          parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      expect(result.value, [
        '[',
        ['[', '*[wtf] what?', ']'],
        ['[', '[lots][of][boxes]', ']'],
        ']'
      ]);
    });
    test('bare HTTP URL', () {
      final result = parser.parse('http://example.com');
      expect(result.value, 'http://example.com');
    });
    test('bare HTTPS URL', () {
      final result = parser.parse('https://example.com');
      expect(result.value, 'https://example.com');
    });
    test('bare file URL', () {
      final result = parser.parse('file:example.txt');
      expect(result.value, 'file:example.txt');
    });
    test('bare attachment URL', () {
      final result = parser.parse('attachment:example.txt');
      expect(result.value, 'attachment:example.txt');
    });
    test('arbitrary protocol', () {
      final result = parser.parse('foobar://example.com');
      expect(result, isA<Failure>());
    });
    test('nested markup', () {
      final result = parser.parse('[[http://example.com][*example*]]');
      expect(
          result.value,
          [
            '[',
            ['[', 'http://example.com', ']'],
            ['[', '*example*', ']'],
            ']'
          ],
          reason: 'description content parsed on separate layer');
    });
  });
}
