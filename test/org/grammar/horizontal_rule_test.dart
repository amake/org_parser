import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('horizontal rule', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.horizontalRule()).end();
    test('minimal', () {
      final result = parser.parse('-----');
      expect(result.value, ['', '-----', '']);
    });
    test('indented', () {
      final result = parser.parse(' -----');
      expect(result.value, [' ', '-----', '']);
    });
    test('trailing', () {
      final result = parser.parse('''-----${' '}

''');
      expect(result.value, ['', '-----', ' \n\n']);
    });
    test('long', () {
      final result = parser.parse('----------------');
      expect(result.value, ['', '----------------', '']);
    });
    test('too short', () {
      final result = parser.parse('----');
      expect(result, isA<Failure>());
    });
    test('trailing garbage', () {
      final result = parser.parse('----- a');
      expect(result, isA<Failure>());
    });
  });
}
