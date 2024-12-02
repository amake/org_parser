import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('radio link', () {
    group('none defined', () {
      final grammar = OrgContentGrammarDefinition();
      final parser = grammar.buildFrom(grammar.radioLink()).end();
      test('non-empty fails', () {
        final result = parser.parse('foo');
        expect(result, isA<Failure>());
      });
      test('empty fails', () {
        final result = parser.parse('');
        expect(result, isA<Failure>());
      });
    });
    group('some defined', () {
      final grammar = OrgContentGrammarDefinition(radioTargets: ['foo', 'bar']);
      test('solitary', () {
        final parser = grammar.buildFrom(grammar.radioLink()).end();
        var result = parser.parse('foo');
        expect(result.value, [null, 'foo', null]);
        result = parser.parse('bar');
        expect(result.value, [null, 'bar', null]);
      });
      test('case-insensitive', () {
        final parser = grammar.buildFrom(grammar.radioLink()).end();
        var result = parser.parse('Foo');
        expect(result.value, [null, 'Foo', null]);
        result = parser.parse('baR');
        expect(result.value, [null, 'baR', null]);
      });
      group('in context', () {
        final parser =
            grammar.buildFrom(any() & grammar.radioLink() & any()).end();
        test('spaces around', () {
          var result = parser.parse(' foo ');
          expect(result.value, [
            ' ',
            [anything, 'foo', anything],
            ' '
          ]);
          result = parser.parse(' bar ');
          expect(result.value, [
            ' ',
            [anything, 'bar', anything],
            ' '
          ]);
        });
        test('non-alphanumeric around', () {
          final result = parser.parse('.foo,');
          expect(result.value, [
            '.',
            [anything, 'foo', anything],
            ','
          ]);
        });
        test('line-breaking around', () {
          final result = parser.parse('あfooお');
          expect(result.value, [
            'あ',
            [anything, 'foo', anything],
            'お'
          ]);
        });
        test('alphanumeric before', () {
          final result = parser.parse('ffoo ');
          expect(result, isA<Failure>());
        });
        test('alphanumeric after', () {
          final result = parser.parse(' foof');
          expect(result, isA<Failure>());
        });
      });
    });
  });
}
