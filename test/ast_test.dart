import 'dart:io';

import 'package:org_parser/org_parser.dart';
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
        final markup = '[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]';
        var result = parser.parse(markup);
        var link = result.value as OrgLink;
        expect(link.contains('what?'), true);
        expect(link.toMarkup(), markup);
      }, skip: 'TODO(aaron): fix link escaping');
      test('link with search option', () {
        final markup = '[[foo::1][bar]]';
        final result = parser.parse(markup);
        final link = result.value as OrgLink;
        expect(link.contains('foo'), true);
        expect(link.toMarkup(), markup);
      });
      test('quotes in search option', () {
        final markup = r'[[foo::"\[1\]"][bar]]';
        final result = parser.parse(markup);
        final link = result.value as OrgLink;
        expect(link.contains('foo'), true);
        expect(link.toMarkup(), markup);
      }, skip: 'TODO(aaron): fix link escaping');
    });
    group('markup', () {
      final parser = buildSpecific(parserDefinition.markups);
      test('with line break', () {
        final markup = '''/foo
bar/''';
        var result = parser.parse(markup);
        final markupNode = result.value as OrgMarkup;
        expect(markupNode.contains('foo'), true);
        expect(markupNode.toMarkup(), markup);
      });
    });
    group('macro reference', () {
      final parser = buildSpecific(parserDefinition.macroReference);
      test('with args', () {
        final markup = '{{{name(arg1, arg2)}}}';
        var result = parser.parse(markup);
        var ref = result.value as OrgMacroReference;
        expect(ref.contains('name'), true);
        expect(ref.toMarkup(), markup);
      });
      test('simple', () {
        final markup = '{{{foobar}}}';
        final result = parser.parse(markup);
        final ref = result.value as OrgMacroReference;
        expect(ref.contains('foobar'), true);
        expect(ref.toMarkup(), markup);
      });
    });
    group('fixed-width area', () {
      final parser = buildSpecific(parserDefinition.fixedWidthArea);
      test('multiline', () {
        final markup = ''': foo
: bar
''';
        var result = parser.parse(markup);
        var area = result.value as OrgFixedWidthArea;
        expect(area.contains('foo'), true);
        expect(area.toMarkup(), markup);
      });
      test('empty', () {
        final markup = ': ';
        final result = parser.parse(markup);
        final area = result.value as OrgFixedWidthArea;
        expect(area.toMarkup(), markup);
      });
    });
    test('block', () {
      final parser = buildSpecific(parserDefinition.block);
      final markup = '''#+begin_example
  echo 'foo'
  rm bar
#+end_example
''';
      final result = parser.parse(markup);
      final block = result.value as OrgBlock;
      expect(block.contains("echo 'foo'"), true);
      expect(block.toMarkup(), markup);
    });
    group('source block', () {
      final parser = buildSpecific(parserDefinition.block);
      test('simple', () {
        final markup = '''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''';
        var result = parser.parse(markup);
        var block = result.value as OrgSrcBlock;
        expect(block.contains("echo 'foo'"), true);
        expect(block.toMarkup(), markup);
      });
      test('empty', () {
        final markup = '''#+begin_src
#+end_src''';
        final result = parser.parse(markup);
        final block = result.value as OrgSrcBlock;
        expect(block.toMarkup(), markup);
      });
    });
    test('greater block', () {
      final parser = buildSpecific(parserDefinition.greaterBlock);
      final markup = '''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''';
      final result = parser.parse(markup);
      final block = result.value as OrgBlock;
      expect(block.contains('bizbaz'), true);
      expect(block.contains('foo ~bar~'), false);
      expect(block.toMarkup(), markup);
    });
    test('arbitrary block', () {
      final parser = buildSpecific(parserDefinition.arbitraryGreaterBlock);
      final markup = '''#+begin_blah
  foo ~bar~
  bizbaz
#+end_blah
''';
      final result = parser.parse(markup);
      final block = result.value as OrgBlock;
      expect(block.contains('bizbaz'), true);
      expect(block.toMarkup(), markup);
    });
    group('table', () {
      final parser = buildSpecific(parserDefinition.table);
      test('simple', () {
        final markup = '''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''';
        final result = parser.parse(markup);
        final table = result.value as OrgTable;
        expect(table.contains('foo'), true);
        expect(table.contains('bar'), true);
        expect(table.contains('*bar*'), false);
        expect(table.toMarkup(), markup);
      }, skip: 'TODO(aaron): fix table whitespace, divider');
      test('empty', () {
        final markup = '||';
        final result = parser.parse(markup);
        final table = result.value as OrgTable;
        expect(table.toMarkup(), markup);
      }, skip: 'TODO(aaron): fix table whitespace');
    });
    test('planning line', () {
      final parser = buildSpecific(parserDefinition.planningLine);
      final markup =
          'CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49';
      final result = parser.parse(markup);
      final planningLine = result.value as OrgPlanningLine;
      expect(planningLine.contains('CLOCK'), true);
      expect(planningLine.toMarkup(), markup);
    });
    group('drawer', () {
      final parser = buildSpecific(parserDefinition.drawer);
      test('indented', () {
        final markup = '''  :foo:
  :bar: baz
  :bizz: buzz
  :end:

''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        expect(drawer.contains('foo'), true);
        expect(drawer.toMarkup(), markup);
      });
      test('simple', () {
        final markup = ''':LOGBOOK:
a
:END:
''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        expect(drawer.contains('a'), true);
        expect(drawer.toMarkup(), markup);
      });
      test('empty', () {
        final markup = ''':FOOBAR:
:END:''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        expect(drawer.toMarkup(), markup);
      });
    });
    group('footnote', () {
      final parser = buildSpecific(parserDefinition.footnote);
      test('simple', () {
        final markup = '[fn:1] foo *bar* biz baz';
        var result = parser.parse(markup);
        final footnote = result.value as OrgFootnote;
        expect(footnote.contains('foo'), true);
        expect(footnote.toMarkup(), markup);
      });
    });
    group('footnote reference', () {
      final parser = buildSpecific(parserDefinition.footnoteReference);
      test('simple', () {
        final markup = '[fn:1]';
        var result = parser.parse(markup);
        final named = result.value as OrgFootnoteReference;
        expect(named.contains('1'), true);
        expect(named.toMarkup(), markup);
      });
      test('with definition', () {
        final markup = '[fn:: who /what/ why]';
        final result = parser.parse(markup);
        final anonymous = result.value as OrgFootnoteReference;
        expect(anonymous.contains('who'), true);
        expect(anonymous.toMarkup(), markup);
      });
      test('with name', () {
        final markup = '[fn:abc123: when /where/ how]';
        final result = parser.parse(markup);
        final inline = result.value as OrgFootnoteReference;
        expect(inline.contains('abc123'), true);
        expect(inline.toMarkup(), markup);
      });
    });
    test('LaTeX block', () {
      final parser = buildSpecific(parserDefinition.latexBlock);
      final markup = r'''\begin{equation}
\begin{matrix}
   a & b \\
   c & d
\end{matrix}
\end{equation}
''';
      final result = parser.parse(markup);
      final latex = result.value as OrgLatexBlock;
      expect(latex.contains(r'\begin{matrix}'), true);
      expect(latex.toMarkup(), markup);
    });
    group('inline LaTeX', () {
      final parser = buildSpecific(parserDefinition.latexInline);
      test(r'single-$ delimiter', () {
        final markup = r'$i$';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('i'), true);
        expect(latex.toMarkup(), markup);
      });
      test(r'double-$ delimiter', () {
        final markup = r'$$ a^2 $$';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('a^2'), true);
        expect(latex.toMarkup(), markup);
      });
      test('paren delimiter', () {
        final markup = r'\( foo \)';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('foo'), true);
        expect(latex.toMarkup(), markup);
      });
      test('bracket delimiter', () {
        final markup = r'\[ bar \]';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('bar'), true);
        expect(latex.toMarkup(), markup);
      });
    });
    group('entity', () {
      final parser = buildSpecific(parserDefinition.entity);
      test('simple', () {
        final markup = r'\frac12';
        final result = parser.parse(markup);
        final entity = result.value as OrgEntity;
        expect(entity.contains('frac12'), true);
        expect(entity.toMarkup(), markup);
      });
      test('with terminator', () {
        final markup = r'\foobar{}';
        final result = parser.parse(markup);
        final entity = result.value as OrgEntity;
        expect(entity.contains('foobar'), true);
        expect(entity.toMarkup(), markup);
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
        final markup = '** TODO [#A] Title foo bar :biz:baz:';
        final result = parser.parse(markup);
        final headline = result.value as OrgHeadline;
        expect(headline.contains('Title foo'), true);
        expect(headline.toMarkup(), markup);
      });
      test('empty', () {
        final markup = '* ';
        final result = parser.parse(markup);
        final headline = result.value as OrgHeadline;
        expect(headline.toMarkup(), markup);
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
      expect(parsed is Success, true);
      final document = parsed.value as OrgDocument;
      expect(document.contains('introduction'), true);
      expect(document.contains('A Headline'), true);
      expect(document.toMarkup(), doc);
    }, skip: 'TODO(aaron): fix headline round-trip');
    test('footnotes', () {
      final parser = org;
      final doc = '''[fn:1] foo bar

biz baz

[fn:2] bazinga


bazoonga''';
      final result = parser.parse(doc);
      expect(result is Success, true);
      final document = result.value as OrgDocument;
      expect(document.contains('foo bar'), true);
      expect(document.contains('bazinga'), true);
      expect(document.toMarkup(), doc);
    });
    test('complex document', () {
      final doc = File('test/org-syntax.org').readAsStringSync();
      final result = parser.parse(doc);
      expect(result is Success, true);
      final document = result.value as OrgDocument;
      expect(document.toMarkup().length, doc.length);
      expect(document.toMarkup(), doc);
    }, skip: 'TODO(aaron): holy grail');
    test('complex document 2', () {
      final doc = File('test/org-manual.org').readAsStringSync();
      final result = parser.parse(doc);
      expect(result is Success, true);
      final document = result.value as OrgDocument;
      expect(document.toMarkup().length, doc.length);
      expect(document.toMarkup(), doc);
    }, skip: 'TODO(aaron): holy grail');
    test('walk tree', () {
      List<String> walkTree<T extends OrgNode>(
        OrgDocument doc, {
        bool Function(T)? kontinue,
      }) {
        final visited = <String>[];
        kontinue ??= (_) => true;
        doc.visit<T>((node) {
          visited.add(node.toString());
          return kontinue!.call(node);
        });
        return visited;
      }

      final result = parser.parse('Hello, world!');
      final doc = result.value as OrgDocument;
      expect(walkTree(doc), [
        'OrgDocument',
        'OrgContent',
        'OrgParagraph',
        'OrgContent',
        'OrgPlainText'
      ]);
      expect(walkTree<OrgPlainText>(doc), ['OrgPlainText']);
      expect(
        walkTree(
          doc,
          kontinue: (node) => node is! OrgParagraph,
        ),
        ['OrgDocument', 'OrgContent', 'OrgParagraph'],
      );
    });
    group('walk sections', () {
      final result = parser.parse('''* Foobar
** Bizzbazz
*** Bingbang
content''');
      final doc = result.value as OrgDocument;
      test('visit all', () {
        final sections = <String?>[];
        doc.visitSections((section) {
          sections.add(section.headline.rawTitle);
          return true;
        });
        expect(sections, ['Foobar', 'Bizzbazz', 'Bingbang']);
      });
      test('visit some', () {
        final sections = <String?>[];
        doc.visitSections((section) {
          sections.add(section.headline.rawTitle);
          return sections.length < 2;
        });
        expect(sections, ['Foobar', 'Bizzbazz']);
      });
    });
    group('section ids', () {
      test('has ids', () {
        final result = parser.parse('''* Foobar
   :properties:
   :bizz: bazz
   :ID:   abcd1234
   :ID: efgh5678
   :CUSTOM_ID: some-id
   :custom_ID: other-id
   :END:

content''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        expect(section.customIds, ['some-id', 'other-id']);
        expect(section.ids, ['abcd1234', 'efgh5678']);
      });
      test('parent has no ids', () {
        final result = parser.parse('''* Foobar
** Bizbaz
   :PROPERTIES:
   :ID: abcd1234
   :END:

content''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        expect(section.customIds.isEmpty, true);
        expect(section.ids.isEmpty, true);
      });
    });
  });
}
