import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link target', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.linkTarget()).end();
    test('single character', () {
      final result = parser.parse('<<!>>');
      expect(result.value, ['<<', '!', '>>']);
    });
    test('multiple words', () {
      final result = parser.parse('<<foo bar>>');
      expect(result.value, ['<<', 'foo bar', '>>']);
    });
    test('too few brackets', () {
      final result = parser.parse('<foo>');
      expect(result, isA<Failure>());
    });
    test('too many brackets', () {
      final result = parser.parse('<<<foo>>>');
      expect(result, isA<Failure>());
    });
  });
}
