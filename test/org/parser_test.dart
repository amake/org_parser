import 'dart:io';

import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/todo/todo.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('content parser parts', () {
    final parserDefinition = OrgContentParserDefinition();
    Parser buildSpecific(Parser Function() start) {
      return parserDefinition.buildFrom(start()).end();
    }

    group('link', () {
      final parser = buildSpecific(parserDefinition.link);
      test('brackets in location', () {
        final result =
            parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
        final link = result.value as OrgBracketLink;
        expect(link.location, '*[wtf] what?');
        expect(link.description, '[lots][of][boxes]');
      });
      test('link with search option', () {
        final result = parser.parse('[[foo::1][bar]]');
        final link = result.value as OrgBracketLink;
        expect(link.description, 'bar');
        expect(link.location, 'foo::1');
      });
      test('quotes in search option', () {
        final result = parser.parse(r'[[foo::"\[1\]"][bar]]');
        final link = result.value as OrgBracketLink;
        expect(link.description, 'bar');
        expect(link.location, 'foo::"[1]"');
      });
      test('no description', () {
        final result = parser.parse('[[foo::1]]');
        final link = result.value as OrgBracketLink;
        expect(link.description, isNull);
        expect(link.location, 'foo::1');
      });
      test('plain link', () {
        final result = parser.parse('http://example.com');
        final link = result.value as OrgLink;
        expect(link.location, 'http://example.com');
      });
    });
    group('markup', () {
      final parser = buildSpecific(parserDefinition.markups);
      test('with line break', () {
        final result = parser.parse('''/foo
bar/''');
        final markup = result.value as OrgMarkup;
        expect(markup.content, 'foo\nbar');
        expect(markup.leadingDecoration, '/');
        expect(markup.trailingDecoration, '/');
        expect(markup.style, OrgStyle.italic);
      });
      test('with too many line breaks', () {
        final result = parser.parse('''/foo

bar/''');
        expect(result, isA<Failure>());
      });
    });
    group('macro reference', () {
      final parser = buildSpecific(parserDefinition.macroReference);
      test('with args', () {
        final result = parser.parse('{{{name(arg1, arg2)}}}');
        final ref = result.value as OrgMacroReference;
        expect(ref.content, '{{{name(arg1, arg2)}}}');
      });
      test('simple', () {
        final result = parser.parse('{{{foobar}}}');
        final ref = result.value as OrgMacroReference;
        expect(ref.content, '{{{foobar}}}');
      });
      test('empty', () {
        final result = parser.parse('{{{}}}');
        expect(result, isA<Failure>(), reason: 'Body missing');
      });
      test('invalid key', () {
        final result = parser.parse('{{{0abc}}}');
        expect(result, isA<Failure>(), reason: 'Invalid key');
      });
    });
    group('fixed-width area', () {
      final parser = buildSpecific(parserDefinition.fixedWidthArea);
      test('multiline', () {
        final result = parser.parse(''': foo
: bar
''');
        final area = result.value as OrgFixedWidthArea;
        expect(area.content, ''': foo
: bar
''');
      });
      test('empty', () {
        final result = parser.parse(': ');
        final area = result.value as OrgFixedWidthArea;
        expect(area.content, ': ');
      });
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
    group('source block', () {
      final parser = buildSpecific(parserDefinition.block);
      test('simple', () {
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
      test('empty', () {
        final result = parser.parse('''#+begin_src
#+end_src''');
        final block = result.value as OrgSrcBlock;
        final body = block.body as OrgPlainText;
        expect(block.language, isNull);
        expect(body.content, '');
      });
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
      final child1 = body.children[0] as OrgPlainText;
      expect(child1.content, '  foo ');
      final child2 = body.children[1] as OrgMarkup;
      expect(child2.content, 'bar');
      expect(block.footer, '#+end_center');
      expect(block.trailing, '\n');
    });
    test('arbitrary block', () {
      final parser = buildSpecific(parserDefinition.arbitraryGreaterBlock);
      final result = parser.parse('''#+begin_blah
  foo ~bar~
  bizbaz
#+end_blah
''');
      final block = result.value as OrgBlock;
      expect(block.header, '#+begin_blah\n');
      final body = block.body as OrgContent;
      final child1 = body.children[0] as OrgPlainText;
      expect(child1.content, '  foo ');
      final child2 = body.children[1] as OrgMarkup;
      expect(child2.content, 'bar');
      expect(block.footer, '#+end_blah');
      expect(block.trailing, '\n');
    });
    group('table', () {
      final parser = buildSpecific(parserDefinition.table);
      test('simple', () {
        final result = parser.parse('''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
        final table = result.value as OrgTable;
        final row0 = table.rows[0] as OrgTableCellRow;
        final row0Cell0 = row0.cells[0].content.children[0] as OrgPlainText;
        expect(row0Cell0.content, 'foo');
        final row0Cell1 = row0.cells[1].content.children[0] as OrgMarkup;
        expect(row0Cell1.content, 'bar');
        expect(row0Cell1.leadingDecoration, '*');
        expect(row0Cell1.trailingDecoration, '*');
        expect(row0.cells.length, 3);
        expect(table.rows[1], isA<OrgTableDividerRow>());
        final row2 = table.rows[2] as OrgTableCellRow;
        expect(row2.cells.length, 3);
      });
      test('empty', () {
        final result = parser.parse('||');
        final table = result.value as OrgTable;
        final row0 = table.rows[0] as OrgTableCellRow;
        expect(row0.cells[0].content.children.isEmpty, isTrue);
      });
    });
    group('list', () {
      final parser = buildSpecific(parserDefinition.list);
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
        expect(markup.content, 'foo');
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
        expect(meta.keyword, '#+vindex:');
      });
    });
    test('planning line', () {
      final parser = buildSpecific(parserDefinition.planningLine);
      final result = parser.parse(
          'CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49');
      final planningLine = result.value as OrgPlanningLine;
      expect(planningLine.keyword.content, 'CLOCK:');
      final text = planningLine.body.children.last as OrgPlainText;
      expect(text.content, ' =>  0:49');
    });
    group('drawer', () {
      final parser = buildSpecific(parserDefinition.drawer);
      test('indented', () {
        final result = parser.parse('''  :foo:
  :bar: baz
  :bizz: buzz
  :end:

''');
        final drawer = result.value as OrgDrawer;
        expect(drawer.header, ':foo:\n');
        expect(drawer.properties().length, 2);
        final body = drawer.body as OrgContent;
        final property = body.children[0] as OrgProperty;
        expect(property.key, ':bar:');
        expect(property.value, ' baz');
        expect(drawer.footer, '  :end:');
        expect(drawer.properties().first, property);
      });
      test('simple', () {
        final result = parser.parse(''':LOGBOOK:
a
:END:
''');
        final drawer = result.value as OrgDrawer;
        expect(drawer.header, ':LOGBOOK:\n');
        expect(drawer.properties().isEmpty, isTrue);
        final body = drawer.body as OrgContent;
        final text = body.children[0] as OrgPlainText;
        expect(text.content, 'a\n');
      });
      test('empty', () {
        final result = parser.parse(''':FOOBAR:
:END:''');
        final drawer = result.value as OrgDrawer;
        expect(drawer.properties().isEmpty, isTrue);
        final body = drawer.body as OrgContent;
        expect(body.children.isEmpty, isTrue);
      });
    });
    group('footnote', () {
      final parser = buildSpecific(parserDefinition.footnote);
      test('simple', () {
        final result = parser.parse('[fn:1] foo *bar* biz baz');
        final footnote = result.value as OrgFootnote;
        expect(footnote.marker.isDefinition, isTrue);
        expect(footnote.marker.name, '1');
        final firstText = footnote.content.children[0] as OrgPlainText;
        expect(firstText.content, ' foo ');
      });
      test('invalid indent', () {
        final result = parser.parse(' [fn:2] bazinga');
        expect(result, isA<Failure>(), reason: 'Indent not allowed');
      });
    });
    group('footnote reference', () {
      final parser = buildSpecific(parserDefinition.footnoteReference);
      test('simple', () {
        var result = parser.parse('[fn:1]');
        final named = result.value as OrgFootnoteReference;
        expect(named.isDefinition, isFalse);
        expect(named.leading, '[fn:');
        expect(named.name, '1');
        expect(named.definition?.delimiter, isNull);
        expect(named.definition, isNull);
        expect(named.trailing, ']');
      });
      test('with definition', () {
        final result = parser.parse('[fn:: who /what/ why]');
        final anonymous = result.value as OrgFootnoteReference;
        expect(anonymous.isDefinition, isFalse);
        expect(anonymous.leading, '[fn:');
        expect(anonymous.name, isNull);
        expect(anonymous.definition?.delimiter, ':');
        final defText0 =
            anonymous.definition!.value.children[0] as OrgPlainText;
        expect(defText0.content, ' who ');
        expect(anonymous.trailing, ']');
      });
      test('with name', () {
        final result = parser.parse('[fn:abc123: when /where/ how]');
        final inline = result.value as OrgFootnoteReference;
        expect(inline.isDefinition, isFalse);
        expect(inline.leading, '[fn:');
        expect(inline.name, 'abc123');
        expect(inline.definition?.delimiter, ':');
        final defText0 = inline.definition!.value.children[0] as OrgPlainText;
        expect(defText0.content, ' when ');
        expect(inline.trailing, ']');
      });
    });
    group('citation', () {
      final parser = buildSpecific(parserDefinition.citation);
      test('simple', () {
        final result = parser.parse('[cite:@foo]');
        final citation = result.value as OrgCitation;
        expect(citation.leading, '[cite');
        expect(citation.style, isNull);
        expect(citation.delimiter, ':');
        expect(citation.body, '@foo');
        expect(citation.trailing, ']');
      });
      test('with style', () {
        final result = parser.parse('[cite/mystyle:@bar]');
        final citation = result.value as OrgCitation;
        expect(citation.leading, '[cite');
        expect(citation.style?.leading, '/');
        expect(citation.style?.value, 'mystyle');
        expect(citation.delimiter, ':');
        expect(citation.body, '@bar');
        expect(citation.trailing, ']');
      });
      test('multiple keys', () {
        final result = parser.parse('[cite:@foo;@bar]');
        final citation = result.value as OrgCitation;
        expect(citation.leading, '[cite');
        expect(citation.style, isNull);
        expect(citation.delimiter, ':');
        expect(citation.body, '@foo;@bar');
        expect(citation.trailing, ']');
      });
      test('prefix and suffix', () {
        final result = parser.parse('[cite:a ;b @foo c; d]');
        final citation = result.value as OrgCitation;
        expect(citation.leading, '[cite');
        expect(citation.style, isNull);
        expect(citation.delimiter, ':');
        expect(citation.body, 'a ;b @foo c; d');
        expect(citation.trailing, ']');
      });
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
      expect(latex.end, r'\end{equation}');
    });
    group('inline LaTeX', () {
      final parser = buildSpecific(parserDefinition.latexInline);
      test(r'single-$ delimiter', () {
        final result = parser.parse(r'$i$');
        final latex = result.value as OrgLatexInline;
        expect(latex.leadingDecoration, r'$');
        expect(latex.content, r'i');
        expect(latex.trailingDecoration, r'$');
      });
      test(r'double-$ delimiter', () {
        final result = parser.parse(r'$$ a^2 $$');
        final latex = result.value as OrgLatexInline;
        expect(latex.leadingDecoration, r'$$');
        expect(latex.content, r' a^2 ');
        expect(latex.trailingDecoration, r'$$');
      });
      test('paren delimiter', () {
        final result = parser.parse(r'\( foo \)');
        final latex = result.value as OrgLatexInline;
        expect(latex.leadingDecoration, r'\(');
        expect(latex.content, r' foo ');
        expect(latex.trailingDecoration, r'\)');
      });
      test('bracket delimiter', () {
        final result = parser.parse(r'\[ bar \]');
        final latex = result.value as OrgLatexInline;
        expect(latex.leadingDecoration, r'\[');
        expect(latex.content, r' bar ');
        expect(latex.trailingDecoration, r'\]');
      });
    });
    group('entity', () {
      final parser = buildSpecific(parserDefinition.entity);
      test('simple', () {
        final result = parser.parse(r'\frac12');
        final entity = result.value as OrgEntity;
        expect(entity.leading, r'\');
        expect(entity.name, r'frac12');
        expect(entity.trailing, '');
      });
      test('with terminator', () {
        final result = parser.parse(r'\foobar{}');
        final entity = result.value as OrgEntity;
        expect(entity.leading, r'\');
        expect(entity.name, r'foobar');
        expect(entity.trailing, '{}');
      });
    });
    group('local variables', () {
      final parser = buildSpecific(parserDefinition.localVariables);
      test('simple', () {
        final result = parser.parse('''# Local Variables:
# foo: bar
# End: ''');
        final variables = result.value as OrgLocalVariables;
        expect(variables.start, '# Local Variables:\n');
        expect(variables.end, '# End: ');
        expect(variables.entries.length, 1);
        expect(
          variables.entries[0],
          (prefix: '# ', content: 'foo: bar', suffix: '\n'),
        );
      });
      test('with indent and suffix', () {
        final result = parser.parse(''' /* Local Variables: */
 /* foo: bar */
 /* baz: bazinga */
 /* End: */''');
        final variables = result.value as OrgLocalVariables;
        expect(variables.start, ' /* Local Variables: */\n');
        expect(variables.end, ' /* End: */');
        expect(variables.entries.length, 2);
        expect(
          variables.entries[0],
          (prefix: ' /* ', content: 'foo: bar ', suffix: '*/\n'),
        );
      });
    });
    group('PGP block', () {
      final parser = buildSpecific(parserDefinition.pgpBlock);
      test('simple', () {
        final result = parser.parse('''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''');
        final block = result.value as OrgPgpBlock;
        expect(block.indent, '');
        expect(block.header, '-----BEGIN PGP MESSAGE-----');
        expect(
          block.body,
          '\n\n'
          'jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
          'X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
          '=chda\n',
        );
        expect(block.footer, '-----END PGP MESSAGE-----');
        expect(block.trailing, '\n');
      });
    });
    group('Comment', () {
      final parser = buildSpecific(parserDefinition.comment);
      test('simple', () {
        final result = parser.parse('# foo bar');
        final comment = result.value as OrgComment;
        expect(comment.indent, '');
        expect(comment.start, '# ');
        expect(comment.content, 'foo bar');
      });
    });
  });
  group('document parser parts', () {
    final parserDefinition = OrgParserDefinition();
    Parser buildSpecific(Parser Function() start) {
      return parserDefinition.buildFrom(start()).end();
    }

    group('header', () {
      final parser = buildSpecific(parserDefinition.headline);
      test('full', () {
        final result = parser.parse('** TODO [#A] Title *foo* bar :biz:baz:');
        final headline = result.value as OrgHeadline;
        final title = headline.title!.children[0] as OrgPlainText;
        expect(title.content, 'Title ');
        final titleEmphasis = headline.title!.children[1] as OrgMarkup;
        expect(titleEmphasis.content, 'foo');
        expect(headline.tags?.values, ['biz', 'baz']);
      });
      test('empty', () {
        final result = parser.parse('* ');
        final headline = result.value as OrgHeadline;
        expect(headline.title, isNull);
      });
      test('with latex', () {
        final result = parser.parse(r'* foo \( \pi \)');
        final headline = result.value as OrgHeadline;
        final [title0, title1] = headline.title!.children;
        expect((title0 as OrgPlainText).content, 'foo ');
        expect((title1 as OrgLatexInline).content, r' \pi ');
      });
    });
  });
  group('parser complete', () {
    final parser = org;
    test('example document', () {
      const doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      final parsed = parser.parse(doc);
      expect(parsed, isA<Success<dynamic>>());
      final document = parsed.value as OrgDocument;
      final paragraph = document.content!.children[0] as OrgParagraph;
      final text = paragraph.body.children[0] as OrgPlainText;
      expect(text.content, 'An introduction.\n\n');
      final topSection = document.sections[0];
      final topContent0 =
          topSection.headline.title!.children[0] as OrgPlainText;
      expect(topContent0.content, 'A Headline');
      expect(topSection.sections.length, 2);
      expect(document.contains('bold'), isTrue);
      expect(
          document.contains('*bold*'), isFalse); // TODO(aaron): could improve?
      expect(document.contains(RegExp(r'Add')), isTrue);
      expect(document.contains(RegExp(r'\bAdd\b')), isFalse);
    });
    test('footnotes', () {
      final parser = org;
      final result = parser.parse('''[fn:1] foo bar

biz baz

[fn:2] bazinga


bazoonga''');
      expect(result, isA<Success<dynamic>>());
      final document = result.value as OrgDocument;
      final footnote0 = document.content!.children[0] as OrgFootnote;
      expect(footnote0.marker.name, '1');
      final footnote0Body = footnote0.content.children[0] as OrgPlainText;
      expect(footnote0Body.content, ' foo bar\n\nbiz baz\n\n');
      final footnote1 = document.content!.children[1] as OrgFootnote;
      final footnote1Body0 = footnote1.content.children[0] as OrgPlainText;
      expect(footnote1Body0.content, ' bazinga');
      final footnote1Body1 = footnote1.content.children[1] as OrgPlainText;
      expect(footnote1Body1.content, '\n\n\n');
      final paragraph = document.content!.children[2] as OrgParagraph;
      final paragraphBody = paragraph.body.children[0] as OrgPlainText;
      expect(paragraphBody.content, 'bazoonga');
    });
    test('footnotes containing meta lines', () {
      final parser = org;
      final result = parser.parse('''[fn:1] foo bar

#+bibliography: baz.bib''');
      expect(result, isA<Success<dynamic>>());
      final document = result.value as OrgDocument;
      final footnote = document.content!.children[0] as OrgFootnote;
      final footnoteBody0 = footnote.content.children[0] as OrgPlainText;
      expect(footnoteBody0.content, ' foo bar\n\n');
      final footnoteBody1 = footnote.content.children[1] as OrgMeta;
      expect(footnoteBody1.keyword, '#+bibliography:');
    });
    group('https://github.com/amake/orgro/issues/16', () {
      test('case 1', () {
        final result = parser.parse('* AB:CD: foo');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'AB:CD: foo');
      });
      test('case 2', () {
        final result = parser.parse('* foo :AB:CD: bar');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'foo :AB:CD: bar');
      });
      test('case 3', () {
        final result = parser.parse('* foo:AB:CD:');
        final document = result.value as OrgDocument;
        final section = document.sections[0];
        expect(section.headline.rawTitle, 'foo:AB:CD:');
      });
    });
    test('https://github.com/amake/orgro/issues/51', () {
      final result = parser.parse('''**${' '}
* foo''');
      final document = result.value as OrgDocument;
      expect(document.sections.length, 2);
      expect(document.sections[0].headline.rawTitle, isNull);
      expect(document.sections[1].headline.rawTitle, 'foo');
    });
    test('https://github.com/amake/orgro/issues/75', () {
      final result = parser.parse(r'''* A $1
* B
1$''');
      final document = result.value as OrgDocument;
      expect(document.sections.length, 2);
      expect(document.sections[0].headline.rawTitle, r'A $1');
    });
    test('complex document', () {
      final result =
          parser.parse(File('test/org-syntax.org').readAsStringSync());
      expect(result, isA<Success<dynamic>>());
    });
    test('complex document 2', () {
      final result =
          parser.parse(File('test/org-manual.org').readAsStringSync());
      expect(result, isA<Success<dynamic>>());
    });
    test('readme example', () {
      final doc = OrgDocument.parse('''* TODO [#A] foo bar
        baz buzz''');
      expect(doc.sections[0].headline.keyword?.value, 'TODO');
    });
  });
  group('custom parser', () {
    group('todo keywords', () {
      final parser = OrgParserDefinition(todoStates: [
        OrgTodoStates(todo: ['FOO'], done: ['BAR'])
      ]).build();
      test('custom keywords', () {
        final doc = parser.parse('''
* FOO [#A] foo bar
  buzz baz
* BAR [#B] bar foo
  baz buzz''').value as OrgDocument;
        expect(doc.sections[0].headline.keyword?.value, 'FOO');
        expect(doc.sections[0].headline.keyword?.done, isFalse);
        expect(doc.sections[1].headline.keyword?.value, 'BAR');
        expect(doc.sections[1].headline.keyword?.done, isTrue);
      });
      test('unrecognized keyword', () {
        final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
        expect(doc.sections[0].headline.keyword?.value, isNull);
        expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
      });
      test('empty states object', () {
        final parser =
            OrgParserDefinition(todoStates: [OrgTodoStates()]).build();
        final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
        expect(doc.sections[0].headline.keyword?.value, isNull);
        expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
      });
      test('empty list of states objects', () {
        final parser = OrgParserDefinition(todoStates: []).build();
        final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
        expect(doc.sections[0].headline.keyword?.value, isNull);
        expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
      });
    });
  });
}
