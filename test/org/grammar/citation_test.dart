import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('citation', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.citation()).end();
    test('simple', () {
      final result = parser.parse('[cite:@key]');
      expect(result.value, ['[cite', null, ':', '@key', ']']);
    });
    test('with style', () {
      final result = parser.parse('[cite/mystyle:@key]');
      expect(result.value, [
        '[cite',
        ['/', 'mystyle'],
        ':',
        '@key',
        ']'
      ]);
    });
    test('multiple keys', () {
      final result = parser.parse('[cite:@key1;@key2;@key3]');
      expect(result.value, ['[cite', null, ':', '@key1;@key2;@key3', ']']);
    });
    test('prefix and suffix', () {
      final result =
          parser.parse('[cite:common pref ;foo @key bar; common suff]');
      expect(result.value,
          ['[cite', null, ':', 'common pref ;foo @key bar; common suff', ']']);
    });
    test('invalid', () {
      final result = parser.parse('[cite:key]');
      expect(result, isA<Failure>());
    });
  });
}
