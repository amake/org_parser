import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('superscript', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = letter() & grammar.buildFrom(grammar.superscript()).end();

    test('single number', () {
      final result = parser.parse('a^4');
      expect(result.value, [
        'a',
        ['^', '4'],
      ]);
    });
    test('single letter', () {
      final result = parser.parse('a^a');
      expect(result.value, [
        'a',
        ['^', 'a'],
      ]);
    });
    test('multiple alphanum', () {
      final result = parser.parse('a^a1b2');
      expect(result.value, [
        'a',
        ['^', 'a1b2'],
      ]);
    });
    test('multiple alphanum fail', () {
      final result = parser.parse('a^a1 b2');
      expect(result, isA<Failure>());
    });
    test('bracketed expression', () {
      final result = parser.parse('a^{a1 b2}');
      expect(result.value, [
        'a',
        ['^', '{a1 b2}'],
      ]);
    });
    test('nested bracketed expression', () {
      final result = parser.parse('a^{a1 {b2}}');
      expect(result.value, [
        'a',
        ['^', '{a1 {b2}}'],
      ]);
    });
    test('sexp', () {
      final result = parser.parse('a^(a1 b2)');
      expect(result.value, [
        'a',
        ['^', '(a1 b2)'],
      ]);
    });
    test('nested sexp', () {
      final result = parser.parse('a^(a1 (b2))');
      expect(result.value, [
        'a',
        ['^', '(a1 (b2))'],
      ]);
    });
    test('asterisk', () {
      final result = parser.parse('a^*');
      expect(result.value, [
        'a',
        ['^', '*'],
      ]);
    });
    test('numerical', () {
      final result = parser.parse('a^-1e24');
      expect(result.value, [
        'a',
        ['^', '-1e24'],
      ]);
    });
    test('non-ASCII', () {
      final result = parser.parse('a^あ');
      expect(result.value, [
        'a',
        ['^', 'あ'],
      ]);
    });
    test('edge case', () {
      final result = parser.parse('a^a..a');
      expect(result.value, [
        'a',
        ['^', 'a..a'],
      ]);
    });
  });
}
