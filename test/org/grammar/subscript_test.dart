import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('subscript', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = letter() & grammar.buildFrom(grammar.subscript()).end();

    test('single number', () {
      final result = parser.parse('a_4');
      expect(result.value, [
        'a',
        ['_', '4'],
      ]);
    });
    test('single letter', () {
      final result = parser.parse('a_a');
      expect(result.value, [
        'a',
        ['_', 'a'],
      ]);
    });
    test('multiple alphanum', () {
      final result = parser.parse('a_a1b2');
      expect(result.value, [
        'a',
        ['_', 'a1b2'],
      ]);
    });
    test('multiple alphanum fail', () {
      final result = parser.parse('a_a1 b2');
      expect(result, isA<Failure>());
    });
    test('bracketed expression', () {
      final result = parser.parse('a_{a1 b2}');
      expect(result.value, [
        'a',
        ['_', '{a1 b2}'],
      ]);
    });
    test('nested bracketed expression', () {
      final result = parser.parse('a_{a1 {b2}}');
      expect(result.value, [
        'a',
        ['_', '{a1 {b2}}'],
      ]);
    });
    test('sexp', () {
      final result = parser.parse('a_(a1 b2)');
      expect(result.value, [
        'a',
        ['_', '(a1 b2)'],
      ]);
    });
    test('nested sexp', () {
      final result = parser.parse('a_(a1 (b2))');
      expect(result.value, [
        'a',
        ['_', '(a1 (b2))'],
      ]);
    });
    test('asterisk', () {
      final result = parser.parse('a_*');
      expect(result.value, [
        'a',
        ['_', '*'],
      ]);
    });
    test('numerical', () {
      final result = parser.parse('a_-1e24');
      expect(result.value, [
        'a',
        ['_', '-1e24'],
      ]);
    });
    test('non-ASCII', () {
      final result = parser.parse('a_あ');
      expect(result.value, [
        'a',
        ['_', 'あ'],
      ]);
    }, skip: 'TODO(aaron): Support non-ASCII subscripts');
    test('edge case', () {
      final result = parser.parse('a_a..a');
      expect(result.value, [
        'a',
        ['_', 'a..a'],
      ]);
    });
  });
}
