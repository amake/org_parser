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
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), markup);
    });
    test('multiple lines', () {
      final markup = '''- foo
  - bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), markup);
    });
    test('multiline item', () {
      final markup = '''- foo

  bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), markup);
    });
    test('multiline item with eol white space', () {
      final markup = '  - foo\n'
          ' \n'
          '    bar';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('bar'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), markup);
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
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), '''30. foo
   - bar :: baz
     blah
   - [ ] bazinga''');
    });
    test('item with block', () {
      final markup = '''- foo
  #+begin_src sh
    echo bar
  #+end_src''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('echo bar'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), markup);
    });
    test('with tag', () {
      final markup = '- ~foo~ ::';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('foo'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), '- foo ::');
    });
    test('with following meta', () {
      final markup = '''- ~foo~ ::
  #+vindex: bar''';
      final result = parser.parse(markup);
      final list = result.value as OrgList;
      expect(list.contains('bar'), isTrue);
      expect(list.contains('あ'), isFalse);
      expect(list.toMarkup(), markup);
      expect(list.toPlainText(), '''- foo ::
  #+vindex: bar''');
    });
    group('toggle checkbox', () {
      final list = parser.parse('''
- [ ] foo
1. bar''').value as OrgList;
      test('toggle checkbox', () {
        final item = list.items[0] as OrgListUnorderedItem;
        expect(item.checkbox, '[ ]');
        final toggled = item.toggleCheckbox();
        expect(toggled.checkbox, '[X]');
        final untoggled = toggled.toggleCheckbox();
        expect(untoggled.checkbox, '[ ]');
        final retoggled = untoggled.toggleCheckbox();
        expect(retoggled.checkbox, '[X]');
      });
      test('toggle checkbox with body', () {
        final item = list.items[1] as OrgListOrderedItem;
        expect(item.checkbox, isNull);
        final toggled = item.toggleCheckbox();
        expect(toggled.checkbox, isNull);
        final forceToggled = item.toggleCheckbox(add: true);
        expect(forceToggled.checkbox, '[ ]');
      });
    });
  });
}
