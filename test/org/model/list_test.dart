import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('list', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.list()).end();
    test('single line', () {
      final markup = '- foo';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('multiple lines', () {
      final markup = '''- foo
  - bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('multiline item', () {
      final markup = '''- foo

  bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('multiline item with eol white space', () {
      final markup = '  - foo\n'
          ' \n'
          '    bar';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('complex', () {
      final markup = '''30. [@30] foo
   - bar :: baz
     blah
   - [ ] *bazinga*''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.contains('baz'), isTrue);
      expect(list.contains('blah'), isTrue);
      expect(list.contains('bazinga'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('item with block', () {
      final markup = '''- foo
  #+begin_src sh
    echo bar
  #+end_src''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('echo bar'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('with tag', () {
      final markup = '- ~foo~ ::';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.toMarkup(), markup);
    });
    test('with following meta', () {
      final markup = '''- ~foo~ ::
  #+vindex: bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('bar'), isTrue);
      expect(list.toMarkup(), markup);
    });
  });
}
