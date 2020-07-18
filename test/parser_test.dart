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
      final result = parser.parse('''#+begin_example
  echo 'foo'
  rm bar
#+end_example
''');
      final block = result.value as OrgBlock;
      final body = block.body as OrgMarkup;
      expect(block.header, '#+begin_example\n');
      expect(body.content, '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_example');
      expect(block.trailing, '\n');
    });
    test('source block', () {
      final parser = buildSpecific(parserDefinition.block);
      final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
      final block = result.value as OrgSrcBlock;
      final body = block.body as OrgPlainText;
      expect(block.language, 'sh');
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
      expect(row0Cell1.content, 'bar');
      expect(row0Cell1.leadingDecoration, '*');
      expect(row0Cell1.trailingDecoration, '*');
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
    test('LaTeX block', () {
      final parser = buildSpecific(parserDefinition.latexBlock);
      final result = parser.parse(r'''\begin{equation}
\begin{matrix}
   a & b \\
   c & d
\end{matrix}
\end{equation}
''');
      final latex = result.value as OrgLatexBlock;
      expect(latex.environment, 'equation');
      expect(latex.begin, r'\begin{equation}');
      expect(latex.content,
          '\n\\begin{matrix}\n   a & b \\\\\n   c & d\n\\end{matrix}\n');
      expect(latex.end, '\\end{equation}');
    });
    test('inline LaTeX', () {
      final parser = buildSpecific(parserDefinition.latexInline);
      var result = parser.parse(r'$i$');
      var latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'$');
      expect(latex.content, r'i');
      expect(latex.trailingDecoration, r'$');
      result = parser.parse(r'$$ a^2 $$');
      latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'$$');
      expect(latex.content, r' a^2 ');
      expect(latex.trailingDecoration, r'$$');
      result = parser.parse(r'\( foo \)');
      latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'\(');
      expect(latex.content, r' foo ');
      expect(latex.trailingDecoration, r'\)');
      result = parser.parse(r'\[ bar \]');
      latex = result.value as OrgLatexInline;
      expect(latex.leadingDecoration, r'\[');
      expect(latex.content, r' bar ');
      expect(latex.trailingDecoration, r'\]');
    });
  });
  group('document parser parts', () {
    final parserDefinition = OrgParserDefinition();
    Parser buildSpecific(Parser Function() start) {
      return parserDefinition.build(start: start).end();
    }

    test('header', () {
      final parser = buildSpecific(parserDefinition.headline);
      final result = parser.parse('** TODO [#A] Title foo bar :biz:baz:');
      final headline = result.value as OrgHeadline;
      final title = headline.title.children[0] as OrgPlainText;
      expect(title.content, 'Title foo bar');
      expect(headline.tags, ['biz', 'baz']);
    });
  });
  group('parser complete', () {
    final parser = OrgParser();
    test('example document', () {
      const doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      expect(parser.parse(doc).isSuccess, true);
      final parsed = parser.parse(doc);
      expect(parsed.isSuccess, true);
      final document = parsed.value as OrgDocument;
      final paragraph = document.content.children[0] as OrgParagraph;
      final text = paragraph.body.children[0] as OrgPlainText;
      expect(text.content, 'An introduction.\n\n');
      final topSection = document.children[0];
      final topContent0 = topSection.headline.title.children[0] as OrgPlainText;
      expect(topContent0.content, 'A Headline');
      expect(topSection.children.length, 2);
    });
    test('footnotes', () {
      final parser = OrgParser();
      final result = parser.parse('''[fn:1] foo bar

biz baz

[fn:2] bazinga


bazoonga''');
      expect(result.isSuccess, true);
      final document = result.value as OrgDocument;
      final footnote0 = document.content.children[0] as OrgFootnote;
      expect(footnote0.marker.name, '1');
      final footnote0Body = footnote0.content.children[0] as OrgPlainText;
      expect(footnote0Body.content, ' foo bar\n\nbiz baz\n\n');
      final footnote1 = document.content.children[1] as OrgFootnote;
      final footnote1Body0 = footnote1.content.children[0] as OrgPlainText;
      expect(footnote1Body0.content, ' bazinga');
      final footnote1Body1 = footnote1.content.children[1] as OrgPlainText;
      expect(footnote1Body1.content, '\n\n\n');
      final paragraph = document.content.children[2] as OrgParagraph;
      final paragraphBody = paragraph.body.children[0] as OrgPlainText;
      expect(paragraphBody.content, 'bazoonga');
    });
    test('https://github.com/amake/orgro/issues/16', () {
      var result = parser.parse('* AB:CD: foo');
      var document = result.value as OrgDocument;
      var section = document.children[0];
      expect(section.headline.rawTitle, 'AB:CD: foo');
      result = parser.parse('* foo :AB:CD: bar');
      document = result.value as OrgDocument;
      section = document.children[0];
      expect(section.headline.rawTitle, 'foo :AB:CD: bar');
      result = parser.parse('* foo:AB:CD:');
      document = result.value as OrgDocument;
      section = document.children[0];
      expect(section.headline.rawTitle, 'foo:AB:CD:');
    });
    test('complex document', () {
      final result =
          parser.parse(File('test/org-syntax.org').readAsStringSync());
      expect(result.isSuccess, true);
    });
    test('complex document 2', () {
      final result =
          parser.parse(File('test/org-manual.org').readAsStringSync());
      expect(result.isSuccess, true);
    });
    test('readme example', () {
      final doc = OrgDocument.parse('''* TODO [#A] foo bar
        baz buzz''');
      expect(doc.children[0].headline.keyword, 'TODO');
    });
  });
}
