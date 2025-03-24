import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('list', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.list()).end();
    test('single line', () {
      final result = parser.parse('- foo');
      final list = result.value as OrgList;
      expect(list.items.length, 1);
      final body = list.items[0].body?.children[0] as OrgPlainText;
      expect(body.content, 'foo');
    });
    test('multiple lines', () {
      final result = parser.parse('''- foo
  - bar''');
      final list = result.value as OrgList;
      expect(list.items.length, 1);
      final sublist = list.items[0].body?.children[1] as OrgList;
      final body = sublist.items[0].body?.children[0] as OrgPlainText;
      expect(body.content, 'bar');
    });
    test('multiline item', () {
      final result = parser.parse('''- foo

  bar''');
      final list = result.value as OrgList;
      expect(list.items.length, 1);
      final body = list.items[0].body?.children[0] as OrgPlainText;
      expect(body.content, 'foo\n\n  bar');
    });
    test('multiline item with eol white space', () {
      final result = parser.parse(
        '  - foo\n'
        ' \n'
        '    bar',
      );
      final list = result.value as OrgList;
      expect(list.items.length, 1);
      final body = list.items[0].body?.children[0] as OrgPlainText;
      expect(body.content, 'foo\n \n    bar');
    });
    test('complex', () {
      final result = parser.parse('''30. [@30] foo
   - bar :: baz
     blah
   - [ ] *bazinga*''');
      final list = result.value as OrgList;
      final item0 = list.items[0] as OrgListOrderedItem;
      expect(item0.bullet, '30. ');
      expect(item0.checkbox, isNull);
      expect(item0.counterSet, '[@30]');
      final sublist = list.items[0].body?.children[1] as OrgList;
      final item1 = sublist.items[0] as OrgListUnorderedItem;
      expect(item1.bullet, '- ');
      expect(item1.checkbox, isNull);
      expect(item1.tag?.delimiter, ' :: ');
    });
    test('item with block', () {
      final result = parser.parse('''- foo
  #+begin_src sh
    echo bar
  #+end_src''');
      final list = result.value as OrgList;
      final block = list.items[0].body?.children[1] as OrgBlock;
      expect(block.header, '#+begin_src sh\n');
    });
    test('with tag', () {
      final result = parser.parse('- ~foo~ ::');
      final list = result.value as OrgList;
      final item = list.items[0] as OrgListUnorderedItem;
      expect(item.tag?.delimiter, ' ::');
      final markup = item.tag?.value.children[0] as OrgMarkup;
      final markupContent = markup.content.children.single as OrgPlainText;
      expect(markupContent.content, 'foo');
    });
    test('with following meta', () {
      final result = parser.parse('''- ~foo~ ::
  #+vindex: bar''');
      final list = result.value as OrgList;
      final item = list.items[0] as OrgListUnorderedItem;
      expect(item.tag?.delimiter, ' ::');
      final text = item.body?.children[0] as OrgPlainText;
      expect(text.content, '\n');
      final meta = item.body?.children[1] as OrgMeta;
      expect(meta.key, '#+vindex:');
    });
    test('trailing space', () {
      final result = parser.parse('''- foo
- bar

''');
      final list = result.value as OrgList;
      final item = list.items[0] as OrgListUnorderedItem;
      final text = item.body?.children[0] as OrgPlainText;
      expect(text.content, 'foo\n');
      final item2 = list.items[1] as OrgListUnorderedItem;
      final text2 = item2.body?.children[0] as OrgPlainText;
      expect(text2.content, 'bar\n');
      expect(list.trailing, '\n');
    });
  });
}
