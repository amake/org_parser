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
    test('macro reference', () {
      final parser = buildSpecific(parserDefinition.macroReference);
      var result = parser.parse('{{{name(arg1, arg2)}}}');
      var ref = result.value as OrgMacroReference;
      expect(ref.content, '{{{name(arg1, arg2)}}}');
      result = parser.parse('{{{foobar}}}');
      ref = result.value as OrgMacroReference;
      expect(ref.content, '{{{foobar}}}');
      result = parser.parse('{{{}}}');
      expect(result.isFailure, true, reason: 'Body missing');
      result = parser.parse('{{{0abc}}}');
      expect(result.isFailure, true, reason: 'Invalid key');
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
    test('footnote', () {
      final parser = buildSpecific(parserDefinition.footnote);
      var result = parser.parse('[fn:1] foo *bar* biz baz');
      final footnote = result.value as OrgFootnote;
      expect(footnote.marker.name, '1');
      final firstText = footnote.content.children[0] as OrgPlainText;
      expect(firstText.content, ' foo ');
      result = parser.parse(' [fn:2] bazinga');
      expect(result.isFailure, true, reason: 'Indent not allowed');
    });
    test('footnote reference', () {
      final parser = buildSpecific(parserDefinition.footnoteReference);
      var result = parser.parse('[fn:1]');
      final named = result.value as OrgFootnoteReference;
      expect(named.leading, '[fn:');
      expect(named.name, '1');
      expect(named.definitionDelimiter, null);
      expect(named.definition, null);
      expect(named.trailing, ']');
      result = parser.parse('[fn:: who /what/ why]');
      final anonymous = result.value as OrgFootnoteReference;
      expect(anonymous.leading, '[fn:');
      expect(anonymous.name, null);
      expect(anonymous.definitionDelimiter, ':');
      var defText0 = anonymous.definition.children[0] as OrgPlainText;
      expect(defText0.content, ' who ');
      expect(anonymous.trailing, ']');
      result = parser.parse('[fn:abc123: when /where/ how]');
      final inline = result.value as OrgFootnoteReference;
      expect(inline.leading, '[fn:');
      expect(inline.name, 'abc123');
      expect(inline.definitionDelimiter, ':');
      defText0 = inline.definition.children[0] as OrgPlainText;
      expect(defText0.content, ' when ');
      expect(inline.trailing, ']');
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
