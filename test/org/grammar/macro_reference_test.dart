import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('macro reference', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.macroReference()).end();
    test('with args', () {
      final result = parser.parse('{{{name(arg1, arg2)}}}');
      expect(result.value, ['{{{', 'name', '(arg1, arg2)', '}}}']);
    });
    test('simple', () {
      final result = parser.parse('{{{foobar}}}');
      expect(result.value, ['{{{', 'foobar', '', '}}}']);
    });
    test('empty', () {
      final result = parser.parse('{{{}}}');
      expect(result, isA<Failure>());
    });
    test('invalid key', () {
      final result = parser.parse('{{{0abc}}}');
      expect(result, isA<Failure>());
    });
  });
}
