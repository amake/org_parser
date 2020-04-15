import 'dart:io';

import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('content parser parts', () {
    final parserDefinition = OrgContentParserDefinition();
    Parser buildSpecific(Parser Function() start) {
      return parserDefinition.build(start: start).end();
    }

    test('link', () {
      final parser = buildSpecific(parserDefinition.link);
      var result =
          parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      var link = result.value as OrgLink;
      expect(link.location, '*[wtf] what?');
      expect(link.description, '[lots][of][boxes]');
      result = parser.parse('[[foo::1][bar]]');
      link = result.value as OrgLink;
      expect(link.description, 'bar');
      expect(link.location, 'foo::1');
      result = parser.parse('[[foo::"\\[1\\]"][bar]]');
      link = result.value as OrgLink;
      expect(link.description, 'bar');
      expect(link.location, 'foo::"[1]"');
    });
    test('block', () {
      final parser = buildSpecific(parserDefinition.block);
      final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
      final block = result.value as OrgBlock;
      final body = block.body as OrgMarkup;
      expect(block.header, '#+begin_src sh\n');
      expect(body.content, '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_src');
      expect(block.trailing, '\n');
    });
    test('greater block', () {
      final parser = buildSpecific(parserDefinition.greaterBlock);
      final result = parser.parse('''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''');
      final block = result.value as OrgBlock;
      expect(block.header, '#+begin_center\n');
      final body = block.body as OrgContent;
      final child = body.children[0] as OrgPlainText;
      expect(child.content, '  foo ');
      expect(block.footer, '#+end_center');
      expect(block.trailing, '\n');
    });
    test('table', () {
      final parser = buildSpecific(parserDefinition.table);
      final result = parser.parse('''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
      final table = result.value as OrgTable;
      final row0 = table.rows[0] as OrgTableCellRow;
      final row0Cell0 = row0.cells[0].children[0] as OrgPlainText;
      expect(row0Cell0.content, 'foo');
      final row0Cell1 = row0.cells[1].children[0] as OrgMarkup;
      expect(row0Cell1.content, '*bar*');
      expect(row0.cells.length, 3);
      final row1 = table.rows[1] as OrgTableDividerRow;
      expect(row1 != null, true);
      final row2 = table.rows[2] as OrgTableCellRow;
      expect(row2.cells.length, 3);
    });
    test('drawer', () {
      final parser = buildSpecific(parserDefinition.drawer);
      final result = parser.parse('''  :foo:
  :bar: baz
  :end:

''');
      final drawer = result.value as OrgDrawer;
      expect(drawer.header, ':foo:\n');
      final body = drawer.body as OrgContent;
      final property = body.children[0] as OrgProperty;
      expect(property.key, ':bar:');
      expect(property.value, ' baz');
      expect(drawer.footer, '  :end:');
    });
  });
  test('complex document', () {
    final result =
        OrgParser().parse(File('test/org-syntax.org').readAsStringSync());
    expect(result.isSuccess, true);
  });
  test('complex document 2', () {
    final result =
        OrgParser().parse(File('test/org-manual.org').readAsStringSync());
    expect(result.isSuccess, true);
  });
}
