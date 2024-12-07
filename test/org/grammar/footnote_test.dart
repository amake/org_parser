import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('footnote', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.footnote()).end();
    test('simple', () {
      final result = parser.parse('[fn:1] foo *bar*');
      expect(result.value, [
        ['[fn:', '1', ']'],
        [
          ' foo ',
          ['*', 'bar', '*']
        ],
        ''
      ]);
    });
    test('multiple lines', () {
      final result = parser.parse('''[fn:1] foo *bar*
baz bazinga

''');
      expect(result.value, [
        ['[fn:', '1', ']'],
        [
          ' foo ',
          ['*', 'bar', '*'],
          '\nbaz bazinga'
        ],
        '\n\n'
      ]);
    });
    test('indented', () {
      final result = parser.parse(' [fn:1] foo *bar*');
      expect(result, isA<Failure>(), reason: 'Indent not allowed');
    });
    test('complex reference', () {
      final result = parser.parse('[fn:1: blah] foo *bar*');
      expect(result, isA<Failure>(), reason: 'Only simple references allowed');
    });
  });
}
