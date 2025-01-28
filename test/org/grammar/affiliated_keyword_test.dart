import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('affiliated keyword', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.affiliatedKeyword()).end();
    test('simple', () {
      final result = parser.parse('#+blah: foo');
      expect(result.value, [
        '',
        ['#+blah:', ' foo'],
        ''
      ]);
    });
    test('trailing', () {
      final result = parser.parse('#+blah: foo\n\n');
      expect(result.value, [
        '',
        ['#+blah:', ' foo'],
        '\n\n'
      ]);
    });
    test('empty value', () {
      final result = parser.parse('#+blah:');
      expect(result.value, [
        '',
        ['#+blah:', ''],
        ''
      ]);
    });
    test('indented', () {
      final result = parser.parse('  #+blah: foo');
      expect(result.value, [
        '  ',
        ['#+blah:', ' foo'],
        ''
      ]);
    });
    test('not at beginning of line', () {
      final result = parser.parse('''a   #+blah''');
      expect(result, isA<Failure>());
    });
    test('missing colon', () {
      final result = parser.parse('''#+blah''');
      expect(result, isA<Failure>());
    });
  });
}
