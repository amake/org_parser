import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote reference', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.footnoteReference()).end();
    test('numeric', () {
      final result = parser.parse('[fn:1]');
      expect(result.value, ['[fn:', '1', ']']);
    });
    test('alphanumeric', () {
      final result = parser.parse('[fn:abc123]');
      expect(result.value, ['[fn:', 'abc123', ']']);
    });
    test('with definition', () {
      final result = parser.parse('[fn:abc123: who what why]');
      expect(result.value, [
        '[fn:',
        'abc123',
        ':',
        [' who what why'],
        ']'
      ]);
    });
    test('with definition with formatting', () {
      final result = parser.parse('[fn:abc123: who *what* why]');
      expect(result.value, [
        '[fn:',
        'abc123',
        ':',
        [
          ' who ',
          ['*', 'what', '*'],
          ' why'
        ],
        ']'
      ]);
    });
  });
}
