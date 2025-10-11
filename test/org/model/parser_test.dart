import 'dart:io';

import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/todo/todo.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
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
      expect(document.contains('あ'), isFalse);
      expect(document.toMarkup(), doc);
      expect(document.toPlainText(), '''An introduction.

* A Headline

  Some text. bold

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''');
    });
    group('footnotes', () {
      test('single blank line continues scope', () {
        final markup = '''[fn:1] foo bar

biz baz
''';
        final doc = parser.parse(markup).value as OrgDocument;
        expect(doc.content!.children.length, 1);
        final footnote = doc.content!.children.single as OrgFootnote;
        expect(footnote.content.children.length, 3);
        expect(footnote.content.children[0], isA<OrgPlainText>());
        expect(footnote.content.children[0].toMarkup(), ' foo bar');
        // This blank-line-only content was the trailing lines of the originally
        // parsed footnote. It's an artifact of fixing up the footnote scope. It
        // would be nicer if it could be put on the previous object.
        expect(footnote.content.children[1], isA<OrgPlainText>());
        expect(footnote.content.children[1].toMarkup(), '\n\n');
        expect(footnote.content.children[2], isA<OrgParagraph>());
        expect(footnote.content.children[2].toMarkup(), 'biz baz\n');
        expect(doc.toMarkup(), markup);
        expect(doc.toPlainText(), '[1] foo bar\n\nbiz baz\n');
      });
      test('double blank line ends scope', () {
        final markup = '''[fn:1] foo bar


biz baz
''';
        final doc = parser.parse(markup).value as OrgDocument;
        expect(doc.content!.children.length, 2);
        final footnote = doc.content!.children[0] as OrgFootnote;
        expect(footnote.content.children.length, 1);
        expect(footnote.content.children.single, isA<OrgPlainText>());
        expect(footnote.content.children.single.toMarkup(), ' foo bar');
        expect(footnote.trailing, '\n\n\n');
        expect(doc.content!.children[1], isA<OrgParagraph>());
        expect(doc.toMarkup(), markup);
        expect(doc.toPlainText(), '[1] foo bar\n\n\nbiz baz\n');
      });
      test('footnote contains elements', () {
        final markup = '''[fn:1] foo bar
#+begin_src
foo
#+end_src
-----
:DRAWER:
blah
:END:
- a
- b
- c
''';
        final doc = parser.parse(markup).value as OrgDocument;
        expect(doc.content!.children.length, 1);
        final footnote = doc.content!.children.single as OrgFootnote;
        expect(footnote.content.children.length, 5);
        expect(footnote.content.children[0], isA<OrgPlainText>());
        expect(footnote.content.children[0].toMarkup(), ' foo bar\n');
        expect(footnote.content.children[1], isA<OrgSrcBlock>());
        expect(footnote.content.children[2], isA<OrgHorizontalRule>());
        expect(footnote.content.children[3], isA<OrgDrawer>());
        expect(footnote.content.children[4], isA<OrgList>());
        expect(doc.toMarkup(), markup);
      });
      test('another footnote breaks scope', () {
        final markup = '''[fn:1] foo bar

biz baz

[fn:2] bazinga
''';
        final doc = parser.parse(markup).value as OrgDocument;
        expect(doc.content!.children.length, 2);
        expect(doc.content!.children[0], isA<OrgFootnote>());
        expect(doc.content!.children[1], isA<OrgFootnote>());
        expect(doc.toMarkup(), markup);
      });
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
        final content = found!.node.content.children.single as OrgPlainText;
        expect(content.content, 'blah');
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
        final content = found!.node.content.children.single as OrgPlainText;
        expect(content.content, 'boo');
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
    test('toMarkup', () {
      final markup = '''
* Foobar
/boo/
''';
      final doc = parser.parse(markup).value as OrgDocument;
      final serializer = _TracingSerializer();
      doc.toMarkup(serializer: serializer);
      expect(serializer.visited, [
        isA<OrgDocument>(),
        isA<OrgSection>(),
        isA<OrgHeadline>(),
        isA<OrgContent>(),
        isA<OrgPlainText>(),
        isA<OrgContent>(),
        isA<OrgParagraph>(),
        isA<OrgContent>(),
        isA<OrgMarkup>(),
        isA<OrgContent>(),
        isA<OrgPlainText>(),
        isA<OrgPlainText>(),
      ]);
      expect(doc.toMarkup(), markup);
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
        final found = doc.find<OrgMarkup>((node) =>
            node.style == OrgStyle.code &&
            node.content.children.single.toMarkup() == 'blah');
        expect(found, isNotNull);
        final tree = doc.findContainingTree(found!.node);
        expect(tree, isNotNull);
        expect(tree, same(doc));
      });
      test('section', () {
        final found = doc.find<OrgMarkup>((node) =>
            node.style == OrgStyle.bold &&
            node.content.children.single.toMarkup() == 'blah');
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
        expect(doc.attachDir, (type: OrgAttachDirType.dir, dir: '/foo/'));
      });
      test('from id', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: abcd1234
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, (type: OrgAttachDirType.id, dir: 'ab/cd1234'));
      });
      test('dir overrides id', () {
        final result = parser.parse('''
:PROPERTIES:
:ID: abcd1234
:DIR: /foo/
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, (type: OrgAttachDirType.dir, dir: '/foo/'));
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
        expect(doc.attachDir, (type: OrgAttachDirType.id, dir: 'ef/gh5678'));
      });
      test('multiple dirs', () {
        final result = parser.parse('''
:PROPERTIES:
:DIR: /foo/
:DIR: /bar/
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.attachDir, (type: OrgAttachDirType.dir, dir: '/bar/'));
      });
    });
    group('properties', () {
      test('simple', () {
        final result = parser.parse('''
:PROPERTIES:
:FOO: foo
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.getProperties(':FOO:'), ['foo']);
        expect(doc.getProperties('FOO'), isEmpty);
        expect(doc.getProperties(':BAR:'), isEmpty);
      });
      test('multiple', () {
        final result = parser.parse('''
:PROPERTIES:
:FOO: foo
:BAR: bar
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.getProperties(':FOO:'), ['foo']);
        expect(doc.getProperties(':BAR:'), ['bar']);
      });
      test('duplicate', () {
        final result = parser.parse('''
:PROPERTIES:
:FOO: foo
:FOO: bar
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.getProperties(':FOO:'), ['foo', 'bar']);
      });
      test('inheritance', () {
        final result = parser.parse('''
:PROPERTIES:
:FOO: foo
:FOO: bar
:END:

* Section
:PROPERTIES:
:FOO: baz
:BAZINGA: qux
:END:
''');
        final doc = result.value as OrgDocument;
        expect(doc.getProperties(':FOO:'), ['foo', 'bar']);
        expect(doc.getProperties(':BAZINGA:'), isEmpty);
        final section = doc.sections[0];
        expect(section.getProperties(':FOO:'), ['baz']);
        expect(section.getProperties(':BAZINGA:'), ['qux']);
        expect(
          section.getPropertiesWithInheritance(':FOO:', doc),
          ['foo', 'bar', 'baz'],
        );
        expect(
          section.getPropertiesWithInheritance(':BAZINGA:', doc),
          ['qux'],
        );
      });
    });
    group('decrypted content', () {
      test('verbatim', () {
        final cleartext = '''foo
* bar
baz''';
        final content = OrgDecryptedContent.fromDecryptedResult(
          cleartext,
          _TestDCSerializer((c) => c.toCleartextMarkup()),
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
          _TestDCSerializer((c) => 'bazinga'),
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
* FOO bar
<<<baz>>>
baz''');
      final section = doc.sections[0];
      final headline = section.headline;
      expect(headline.keyword, isNull);
      expect(headline.rawTitle, 'FOO bar');
      final radioLink = doc.find<OrgRadioLink>((_) => true);
      expect(radioLink, isNull);
    });
    test('parse with interpreting settings', () {
      final doc = OrgDocument.parse('''
#+TODO: FOO BAR
* FOO bar
<<<baz>>>
baz''', interpretEmbeddedSettings: true);
      final section = doc.sections[0];
      final headline = section.headline;
      expect(headline.keyword?.value, 'FOO');
      expect(headline.keyword?.done, isFalse);
      expect(headline.rawTitle, 'bar');
      final radioLink = doc.find<OrgRadioLink>((_) => true);
      expect(radioLink!.node.content, 'baz');
    });
  });
}

class _TestDCSerializer extends DecryptedContentSerializer {
  _TestDCSerializer(this._toMarkup);

  final String Function(OrgDecryptedContent) _toMarkup;

  @override
  String toMarkup(OrgDecryptedContent content) => _toMarkup(content);
}

class _TracingSerializer extends OrgSerializer {
  final visited = <OrgNode>[];

  @override
  void visit(OrgNode node) {
    visited.add(node);
    super.visit(node);
  }
}
