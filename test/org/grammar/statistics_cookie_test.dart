import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('progress cookie', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.statsCookie()).end();
    group('percentage', () {
      test('simple', () {
        final result = parser.parse('[50%]');
        expect(result.value, ['[', '50', '%', ']']);
      });
      test('empty', () {
        final result = parser.parse('[%]');
        expect(result.value, ['[', '', '%', ']']);
      });
      test('invalid', () {
        final result = parser.parse('[1/2/3]');
        expect(result, isA<Failure>());
      });
    });
    group('fraction', () {
      test('simple', () {
        final result = parser.parse('[1/2]');
        expect(result.value, ['[', '1', '/', '2', ']']);
      });
      test('empty', () {
        final result = parser.parse('[/]');
        expect(result.value, ['[', '', '/', '', ']']);
      });
      test('partial', () {
        final result = parser.parse('[/2]');
        expect(result.value, ['[', '', '/', '2', ']']);
      });
      test('invalid', () {
        final result = parser.parse('[50%50]');
        expect(result, isA<Failure>());
      });
    });
    group('invalid', () {
      test('empty', () {
        final result = parser.parse('[]');
        expect(result, isA<Failure>());
      });
      test('both delimiters', () {
        final result = parser.parse('[1/2%]');
        expect(result, isA<Failure>());
      });
    });
  });
}
