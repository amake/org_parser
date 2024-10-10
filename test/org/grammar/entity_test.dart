import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('entity', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.entity()).end();
    test('there4', () {
      final result = parser.parse(r'\there4');
      expect(result.value, [r'\', 'there4', '']);
    });
    test('sup valid', () {
      final result = parser.parse(r'\sup1');
      expect(result.value, [r'\', 'sup1', '']);
    });
    test('sup invalid', () {
      final result = parser.parse(r'\sup5');
      expect(result, isA<Failure>());
    });
    test('valid frac', () {
      final result = parser.parse(r'\frac12');
      expect(result.value, [r'\', 'frac12', '']);
    });
    test('invalid frac', () {
      final result = parser.parse(r'\frac15');
      expect(result, isA<Failure>());
    });
    test('arbitrary alphabetical', () {
      final result = parser.parse(r'\foobar');
      expect(result.value, [r'\', 'foobar', '']);
    });
    test('arbitrary alphanumeric', () {
      final result = parser.parse(r'\foobar2');
      expect(result, isA<Failure>());
    });
    test('with terminator', () {
      final result = parser.parse(r'\foobar{}');
      expect(result.value, [r'\', 'foobar', '{}']);
    });
  });
}
