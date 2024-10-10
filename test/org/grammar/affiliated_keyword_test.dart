import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('affiliated keyword', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.affiliatedKeyword()).end();
    test('indented', () {
      final result = parser.parse('  #+blah');
      expect(result.value, ['  ', '#+blah', '']);
    });
    test('not at beginning of line', () {
      final result = parser.parse('''a   #+blah''');
      expect(result, isA<Failure>());
    });
  });
}
