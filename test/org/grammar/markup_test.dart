import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('markup', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.markups()).end();
    test('bad pre and post chars', () {
      final result = parser.parse('''a/b
c/d''');
      expect(result, isA<Failure>());
    });
    test('bad post char', () {
      final result = parser.parse('''a /b
c/d''');
      expect(result, isA<Failure>());
    });
    test('bad pre char', () {
      final result = parser.parse('''a/b
c/ d''');
      expect(result, isA<Failure>());
    });
    test('single char', () {
      final result = parser.parse('/a/');
      expect(result.value, ['/', 'a', '/']);
    });
    test('single word', () {
      final result = parser.parse('/abc/');
      expect(result.value, ['/', 'abc', '/']);
    });
    test('multiple words', () {
      final result = parser.parse('/a b/');
      expect(result.value, ['/', 'a b', '/']);
    });
    test('empty', () {
      final result = parser.parse('//');
      expect(result, isA<Failure>());
    });
    test('single comma', () {
      final result = parser.parse('~,~');
      expect(result.value, ['~', ',', '~']);
    });
    test('single apostrophe', () {
      final result = parser.parse("~'~");
      expect(result.value, ['~', "'", '~']);
    });
    test('with delimiters inside', () {
      final result = parser.parse('=+LEVEL=3+boss-TODO​="DONE"=');
      expect(result.value, ['=', '+LEVEL=3+boss-TODO​="DONE"', '=']);
    });
    test('with line break', () {
      final result = parser.parse('''+foo
bar+''');
      expect(result.value, ['+', 'foo\nbar', '+']);
    });
    test('too many line breaks', () {
      final result = parser.parse('''+foo

bar+''');
      expect(result, isA<Failure>());
    });
  });
}
