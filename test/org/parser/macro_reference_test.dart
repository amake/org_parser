import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('macro reference', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.macroReference()).end();
    test('with args', () {
      final result = parser.parse('{{{name(arg1, arg2)}}}');
      final ref = result.value as OrgMacroReference;
      expect(ref.content, '{{{name(arg1, arg2)}}}');
    });
    test('simple', () {
      final result = parser.parse('{{{foobar}}}');
      final ref = result.value as OrgMacroReference;
      expect(ref.content, '{{{foobar}}}');
    });
    test('empty', () {
      final result = parser.parse('{{{}}}');
      expect(result, isA<Failure>(), reason: 'Body missing');
    });
    test('invalid key', () {
      final result = parser.parse('{{{0abc}}}');
      expect(result, isA<Failure>(), reason: 'Invalid key');
    });
  });
}
