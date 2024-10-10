import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('Comment', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.comment()).end();
    test('simple', () {
      final result = parser.parse('''# foo bar''');
      expect(result.value, ['', '# ', 'foo bar']);
    });
    test('indented', () {
      final result = parser.parse('''   # foo bar''');
      expect(result.value, ['   ', '# ', 'foo bar']);
    });
  });
}
