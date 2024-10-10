import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('fixed-width area', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.fixedWidthArea()).end();
    test('single line', () {
      final result = parser.parse('  : foo');
      expect(result.value, [
        [
          ['  ', ': ', 'foo']
        ],
        ''
      ]);
    });
    test('multiple lines', () {
      final result = parser.parse('''  : foo
  : bar''');
      expect(result.value, [
        [
          ['  ', ': ', 'foo\n'],
          ['  ', ': ', 'bar']
        ],
        ''
      ]);
    });
  });
}
