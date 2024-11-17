import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('horizontal rule', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.horizontalRule()).end();
    test('minimal', () {
      final result = parser.parse('-----');
      expect(result.value, ['-----', '']);
    });
    test('trailing', () {
      final result = parser.parse('''-----${' '}
''');
      expect(result.value, ['-----', ' \n']);
    });
    test('long', () {
      final result = parser.parse('----------------');
      expect(result.value, ['----------------', '']);
    });
    test('too short', () {
      final result = parser.parse('----');
      expect(result, isA<Failure>());
    });
  });
}
