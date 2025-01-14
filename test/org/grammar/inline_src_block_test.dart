import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('inline src', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.inlineSourceBlock()).end();
    test('no args', () {
      final result = parser.parse('''src_sh{echo "foo"}''');
      expect(result.value, ['src_', 'sh', null, '{echo "foo"}']);
    });
    test('with args', () {
      final result = parser.parse('''src_sh[:exports code]{echo "foo"}''');
      expect(result.value, ['src_', 'sh', '[:exports code]', '{echo "foo"}']);
    });
    test('missing lang', () {
      final result = parser.parse('''src_[:exports code]{echo "foo"}''');
      expect(result, isA<Failure>());
    });
    test('args contains bracket', () {
      final result = parser.parse(r'''src_sh[:var foo="[a]"]{echo $foo}''');
      expect(result, isA<Failure>());
    });
    test('body contains brace', () {
      final result = parser.parse(r'''src_sh{echo "${foo}"}''');
      expect(result, isA<Failure>());
    });
  });
}
