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
        final markup = '[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]';
        var result = parser.parse(markup);
        var link = result.value as OrgBracketLink;
        expect(link.contains('what?'), isTrue);
        expect(link.toMarkup(), markup);
      });
      test('link with search option', () {
        final markup = '[[foo::1][bar]]';
        final result = parser.parse(markup);
        final link = result.value as OrgBracketLink;
        expect(link.contains('foo'), isTrue);
        expect(link.toMarkup(), markup);
      });
      test('quotes in search option', () {
        final markup = r'[[foo::"\[1\]"][bar]]';
        final result = parser.parse(markup);
        final link = result.value as OrgBracketLink;
        expect(link.contains('foo'), isTrue);
        expect(link.toMarkup(), markup);
      });
      test('no description', () {
        final markup = '[[foo::1]]';
        final result = parser.parse(markup);
        final link = result.value as OrgBracketLink;
        expect(link.contains('foo'), isTrue);
        expect(link.toMarkup(), markup);
      });
      test('plain link', () {
        final markup = 'http://example.com';
        final result = parser.parse(markup);
        final link = result.value as OrgLink;
        expect(link.contains('example'), isTrue);
        expect(link.toMarkup(), markup);
      });
    });
    group('markup', () {
      final parser = buildSpecific(parserDefinition.markups);
      test('with line break', () {
        final markup = '''/foo
bar/''';
        var result = parser.parse(markup);
        final markupNode = result.value as OrgMarkup;
        expect(markupNode.contains('foo'), isTrue);
        expect(markupNode.toMarkup(), markup);
      });
    });
    group('macro reference', () {
      final parser = buildSpecific(parserDefinition.macroReference);
      test('with args', () {
        final markup = '{{{name(arg1, arg2)}}}';
        var result = parser.parse(markup);
        var ref = result.value as OrgMacroReference;
        expect(ref.contains('name'), isTrue);
        expect(ref.toMarkup(), markup);
      });
      test('simple', () {
        final markup = '{{{foobar}}}';
        final result = parser.parse(markup);
        final ref = result.value as OrgMacroReference;
        expect(ref.contains('foobar'), isTrue);
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
        expect(area.contains('foo'), isTrue);
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
      expect(block.contains("echo 'foo'"), isTrue);
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
        expect(block.contains("echo 'foo'"), isTrue);
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
      expect(block.contains('bizbaz'), isTrue);
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
      expect(block.contains('bizbaz'), isTrue);
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
        expect(table.contains('foo'), isTrue);
        expect(table.contains('bar'), isTrue);
        expect(table.contains('*bar*'), false);
        expect(table.toMarkup(), markup);
      });
      test('empty', () {
        final markup = '||';
        final result = parser.parse(markup);
        final table = result.value as OrgTable;
        expect(table.toMarkup(), markup);
      });
    });
    group('list', () {
      final parser = buildSpecific(parserDefinition.list);
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
    test('planning line', () {
      final parser = buildSpecific(parserDefinition.planningLine);
      final markup =
          'CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49';
      final result = parser.parse(markup);
      final planningLine = result.value as OrgPlanningLine;
      expect(planningLine.contains('CLOCK'), isTrue);
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
        expect(drawer.contains('foo'), isTrue);
        expect(drawer.toMarkup(), markup);
      });
      test('simple', () {
        final markup = ''':LOGBOOK:
a
:END:
''';
        final result = parser.parse(markup);
        final drawer = result.value as OrgDrawer;
        expect(drawer.contains('a'), isTrue);
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
        expect(footnote.contains('foo'), isTrue);
        expect(footnote.toMarkup(), markup);
      });
    });
    group('footnote reference', () {
      final parser = buildSpecific(parserDefinition.footnoteReference);
      test('simple', () {
        final markup = '[fn:1]';
        var result = parser.parse(markup);
        final named = result.value as OrgFootnoteReference;
        expect(named.contains('1'), isTrue);
        expect(named.toMarkup(), markup);
      });
      test('with definition', () {
        final markup = '[fn:: who /what/ why]';
        final result = parser.parse(markup);
        final anonymous = result.value as OrgFootnoteReference;
        expect(anonymous.contains('who'), isTrue);
        expect(anonymous.toMarkup(), markup);
      });
      test('with name', () {
        final markup = '[fn:abc123: when /where/ how]';
        final result = parser.parse(markup);
        final inline = result.value as OrgFootnoteReference;
        expect(inline.contains('abc123'), isTrue);
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
      expect(latex.contains(r'\begin{matrix}'), isTrue);
      expect(latex.toMarkup(), markup);
    });
    group('inline LaTeX', () {
      final parser = buildSpecific(parserDefinition.latexInline);
      test(r'single-$ delimiter', () {
        final markup = r'$i$';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('i'), isTrue);
        expect(latex.toMarkup(), markup);
      });
      test(r'double-$ delimiter', () {
        final markup = r'$$ a^2 $$';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('a^2'), isTrue);
        expect(latex.toMarkup(), markup);
      });
      test('paren delimiter', () {
        final markup = r'\( foo \)';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('foo'), isTrue);
        expect(latex.toMarkup(), markup);
      });
      test('bracket delimiter', () {
        final markup = r'\[ bar \]';
        final result = parser.parse(markup);
        final latex = result.value as OrgLatexInline;
        expect(latex.contains('bar'), isTrue);
        expect(latex.toMarkup(), markup);
      });
    });
    group('entity', () {
      final parser = buildSpecific(parserDefinition.entity);
      test('simple', () {
        final markup = r'\frac12';
        final result = parser.parse(markup);
        final entity = result.value as OrgEntity;
        expect(entity.contains('frac12'), isTrue);
        expect(entity.toMarkup(), markup);
      });
      test('with terminator', () {
        final markup = r'\foobar{}';
        final result = parser.parse(markup);
        final entity = result.value as OrgEntity;
        expect(entity.contains('foobar'), isTrue);
        expect(entity.toMarkup(), markup);
      });
    });
    group('local variables', () {
      final parser = buildSpecific(parserDefinition.localVariables);
      test('simple', () {
        final markup = '''# Local Variables:
# foo: bar
# End: ''';
        final result = parser.parse(markup);
        final lvars = result.value as OrgLocalVariables;
        expect(lvars.contains('foo'), isTrue);
        expect(lvars.toMarkup(), markup);
      });
      test('with suffix', () {
        final markup = '''# Local Variables: #
# foo: bar #
# End: #''';
        final result = parser.parse(markup);
        final lvars = result.value as OrgLocalVariables;
        expect(lvars.contains('foo'), isTrue);
        expect(lvars.toMarkup(), markup);
      });
    });
    group('PGP block', () {
      final parser = buildSpecific(parserDefinition.pgpBlock);
      test('simple', () {
        final markup = '''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''';
        final result = parser.parse(markup);
        final pgp = result.value as OrgPgpBlock;
        expect(pgp.contains('BEGIN PGP MESSAGE'), isTrue);
        expect(pgp.toMarkup(), markup);
        expect(pgp.toRfc4880(), markup.trim());
      });
      test('indented', () {
        final markup = '''   -----BEGIN PGP MESSAGE-----

   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
   =chda
   -----END PGP MESSAGE-----
''';
        final result = parser.parse(markup);
        final pgp = result.value as OrgPgpBlock;
        expect(pgp.contains('BEGIN PGP MESSAGE'), isTrue);
        expect(pgp.toMarkup(), markup);
        expect(pgp.toRfc4880(), '''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----''');
      });
    });
    group('Comments', () {
      final parser = buildSpecific(parserDefinition.comment);
      test('simple', () {
        final markup = '# foo bar';
        final result = parser.parse(markup);
        final comment = result.value as OrgComment;
        expect(comment.contains('foo'), isTrue);
        expect(comment.toMarkup(), markup);
      });
    });
    group('Citations', () {
      final parser = buildSpecific(parserDefinition.citation);
      test('simple', () {
        final markup = '[cite:@foo]';
        final result = parser.parse(markup);
        final citation = result.value as OrgCitation;
        expect(citation.body, '@foo');
        expect(citation.getKeys(), ['foo']);
        expect(citation.toMarkup(), markup);
      });
      test('multiple keys', () {
        final markup = '[cite:@foo;@bar;@foo]';
        final result = parser.parse(markup);
        final citation = result.value as OrgCitation;
        expect(citation.body, '@foo;@bar;@foo');
        expect(citation.getKeys(), ['foo', 'bar', 'foo']);
        expect(citation.toMarkup(), markup);
      });
      test('prefix and suffix', () {
        final markup = '[cite/style:pre;pre2@bar suff;suff2]';
        final result = parser.parse(markup);
        final citation = result.value as OrgCitation;
        expect(citation.body, 'pre;pre2@bar suff;suff2');
        expect(citation.getKeys(), ['bar']);
        expect(citation.toMarkup(), markup);
      });
      test('invalid', () {
        final markup = '[cite:foo]';
        final result = parser.parse(markup);
        expect(result, isA<Failure>());
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
        expect(headline.contains('Title foo'), isTrue);
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
      expect(parsed is Success, isTrue);
      final document = parsed.value as OrgDocument;
      expect(document.contains('introduction'), isTrue);
      expect(document.contains('A Headline'), isTrue);
      expect(document.toMarkup(), doc);
    });
    test('footnotes', () {
      final parser = org;
      final doc = '''[fn:1] foo bar

biz baz

[fn:2] bazinga


bazoonga''';
      final result = parser.parse(doc);
      expect(result is Success, isTrue);
      final document = result.value as OrgDocument;
      expect(document.contains('foo bar'), isTrue);
      expect(document.contains('bazinga'), isTrue);
      expect(document.toMarkup(), doc);
    });
    test('complex document', () {
      final doc = File('test/org-syntax.org').readAsStringSync();
      final result = parser.parse(doc);
      expect(result is Success, isTrue);
      final document = result.value as OrgDocument;
      expect(document.toMarkup().length, doc.length);
      expect(document.toMarkup(), doc);
    });
    test('complex document 2', () {
      final doc = File('test/org-manual.org').readAsStringSync();
      final result = parser.parse(doc);
      expect(result is Success, isTrue);
      final document = result.value as OrgDocument;
      expect(document.toMarkup().length, doc.length);
      expect(document.toMarkup(), doc);
    });
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
    group('find', () {
      final result = parser.parse('''* Foobar
** Bizzbazz
/boo/
*** Bingbang
*blah*''');
      final doc = result.value as OrgDocument;
      test('find deep with type', () {
        var visited = 0;
        final found = doc.find<OrgMarkup>((node) {
          visited += 1;
          return node.style == OrgStyle.bold;
        });
        expect(found, isNotNull);
        expect(found!.node.content, 'blah');
        expect(visited, 2);
        expect(found.path.map((n) => n.toString()), [
          'OrgDocument',
          'OrgSection',
          'OrgSection',
          'OrgSection',
          'OrgContent',
          'OrgParagraph',
          'OrgContent',
          'OrgMarkup'
        ]);
      });
      test('find shallow with type', () {
        var visited = 0;
        final found = doc.find<OrgMarkup>((node) {
          visited += 1;
          return node.style == OrgStyle.italic;
        });
        expect(found, isNotNull);
        expect(found!.node.content, 'boo');
        expect(visited, 1);
        expect(found.path.map((n) => n.toString()), [
          'OrgDocument',
          'OrgSection',
          'OrgSection',
          'OrgContent',
          'OrgParagraph',
          'OrgContent',
          'OrgMarkup'
        ]);
      });
    });
    group('find containing tree', () {
      final result = parser.parse('''
~blah~
* Foobar
** Bizzbazz
/boo/
*** Bingbang
*blah*''');
      final doc = result.value as OrgDocument;
      test('root', () {
        final found = doc.find<OrgMarkup>(
            (node) => node.style == OrgStyle.code && node.content == 'blah');
        expect(found, isNotNull);
        final tree = doc.findContainingTree(found!.node);
        expect(tree, isNotNull);
        expect(tree, same(doc));
      });
      test('section', () {
        final found = doc.find<OrgMarkup>(
            (node) => node.style == OrgStyle.bold && node.content == 'blah');
        expect(found, isNotNull);
        final tree = doc.findContainingTree(found!.node);
        expect(tree, isNotNull);
        expect(tree, isA<OrgSection>());
        expect((tree as OrgSection).headline.toMarkup(), '*** Bingbang\n');
      });
    });
    group('local variables', () {
      test('simple', () {
        final result = parser.parse(r'''* foo
blah

# Local Variables:
# my-foo: bar
# my-bar: baz\\
# eval: (list 'a
#             'b)
# End:''');
        final doc = result.value as OrgDocument;
        final found = doc.find<OrgLocalVariables>((_) => true);
        expect(found, isNotNull);
        final lvars = found!.node;
        expect(lvars.contentString, r'''my-foo: bar
my-bar: baz\\
eval: (list 'a
            'b)''');
      });
    });
    group('ids', () {
      test('root has ids', () {
        final result = parser.parse('''
:PROPERTIES:
:ID:   abcd1234
:CUSTOM_ID: some-id
:END:

content''');
        final doc = result.value as OrgDocument;
        expect(doc.ids, ['abcd1234']);
        expect(doc.customIds, ['some-id']);
      });
      test('section has ids', () {
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
        expect(section.customIds.isEmpty, isTrue);
        expect(section.ids.isEmpty, isTrue);
      });
    });
    group('dirs', () {
      test('root dir', () {
        final result = parser.parse('''
:PROPERTIES:
:DIR: /foo/
:END:

content''');
        final doc = result.value as OrgDocument;
        expect(doc.dirs, ['/foo/']);
      });
      test('section dir', () {
        final result = parser.parse('''* Foobar
   :properties:
   :DIR: /foo/
   :END:

content''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        expect(section.dirs, ['/foo/']);
      });
    });
    group('attach dir', () {
      test('from dir', () {
        final result = parser.parse('''
:PROPERTIES:
:DIR: /foo/
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, '/foo/');
      });
      test('from id', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: abcd1234
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, 'data/ab/cd1234');
      });
      test('dir overrides id', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: abcd1234
:DIR: /foo/
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, '/foo/');
      });
      test('invalid id', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: a
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, isNull);
      });
      test('multiple ids', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: abcd1234
:ID: efgh5678
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, 'data/ef/gh5678');
      });
      test('multiple dirs', () {
        final result = parser.parse('''
:PROPERTIES:
:DIR: /foo/
:DIR: /bar/
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, '/bar/');
      });
    });
    group('decrypted content', () {
      test('verbatim', () {
        final cleartext = '''foo
* bar
baz''';
        final content = OrgDecryptedContent.fromDecryptedResult(
          cleartext,
          _TestSerializer((c) => c.toCleartextMarkup()),
        );
        expect(content.toCleartextMarkup(), cleartext);
        expect(content.toMarkup(), cleartext);
      });
      test('custom', () {
        final cleartext = '''foo
* bar
baz''';
        final content = OrgDecryptedContent.fromDecryptedResult(
          cleartext,
          _TestSerializer((c) => 'bazinga'),
        );
        expect(content.toCleartextMarkup(), cleartext);
        expect(content.toMarkup(), 'bazinga');
      });
    });
    group('cycle todo', () {
      final result = parser.parse('''* foo''');
      final doc = result.value as OrgDocument;
      final section = doc.sections[0];
      final headline = section.headline;
      test('defaults', () {
        final todo = headline.cycleTodo();
        expect(todo.toMarkup(), '* TODO foo');
        final done = todo.cycleTodo();
        expect(done.toMarkup(), '* DONE foo');
        final none = done.cycleTodo();
        expect(none.toMarkup(), '* foo');
      });
      test('custom settings', () {
        final todoSettings = [
          OrgTodoStates(todo: ['A', 'B'], done: ['C', 'D'])
        ];
        final a = headline.cycleTodo(todoSettings);
        expect(a.toMarkup(), '* A foo');
        final b = a.cycleTodo(todoSettings);
        expect(b.toMarkup(), '* B foo');
        final c = b.cycleTodo(todoSettings);
        expect(c.toMarkup(), '* C foo');
        final d = c.cycleTodo(todoSettings);
        expect(d.toMarkup(), '* D foo');
        final none = d.cycleTodo(todoSettings);
        expect(none.toMarkup(), '* foo');
      });
      test('repeated state', () {
        final todoSettings = [
          OrgTodoStates(todo: ['A', 'A'])
        ];
        final a = headline.cycleTodo(todoSettings);
        expect(a.toMarkup(), '* A foo');
        final a2 = a.cycleTodo(todoSettings);
        expect(a2.toMarkup(), '* A foo');
      });
      test('missing state', () {
        final a = headline.cycleTodo([
          OrgTodoStates(todo: ['A'])
        ]);
        expect(a.toMarkup(), '* A foo');
        expect(
          () => a.cycleTodo([
            OrgTodoStates(todo: ['B'])
          ]),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('empty state', () {
        final todoSettings = [OrgTodoStates()];
        final a = headline.cycleTodo(todoSettings);
        expect(a.toMarkup(), '* foo');
        final a2 = a.cycleTodo(todoSettings);
        expect(a2.toMarkup(), '* foo');
      });
    });
  });
  group('model entrypoint', () {
    test('parse without interpreting settings', () {
      final doc = OrgDocument.parse('''
#+TODO: FOO
* FOO bar''');
      final section = doc.sections[0];
      final headline = section.headline;
      expect(headline.keyword, isNull);
      expect(headline.rawTitle, 'FOO bar');
    });
    test('parse with interpreting settings', () {
      final doc = OrgDocument.parse('''
#+TODO: FOO BAR
* FOO bar''', interpretEmbeddedSettings: true);
      final section = doc.sections[0];
      final headline = section.headline;
      expect(headline.keyword?.value, 'FOO');
      expect(headline.keyword?.done, isFalse);
      expect(headline.rawTitle, 'bar');
    });
  });
}

class _TestSerializer extends DecryptedContentSerializer {
  _TestSerializer(this._toMarkup);

  final String Function(OrgDecryptedContent) _toMarkup;

  @override
  String toMarkup(OrgDecryptedContent content) => _toMarkup(content);
}
