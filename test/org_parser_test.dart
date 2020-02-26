import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('structural grammar', () {
    final grammar = OrgGrammar();
    final parser = OrgParser();
    test('parse content', () {
      final result = grammar.parse('''foo
bar
''');
      expect(result.value, ['foo\nbar\n', []]);
    });
    test('parse a header', () {
      final result = grammar.parse('* Title');
      expect(result.value, [
        null,
        [
          [
            ['*', null, null, 'Title', null],
            null
          ]
        ]
      ]);
    });
    test('parse a todo header', () {
      final result = grammar.parse('* TODO Title');
      expect(result.value, [
        null,
        [
          [
            ['*', 'TODO', null, 'Title', null],
            null
          ]
        ]
      ]);
    });
    test('parse a section', () {
      final result = grammar.parse('''* Title
  Content1
  Content2''');
      expect(result.value, [
        null,
        [
          [
            ['*', null, null, 'Title', null],
            '  Content1\n  Content2'
          ]
        ]
      ]);
    });
    test('valid headers', () {
      for (final valid in [
        '* ',
        '** DONE',
        '*** Some e-mail',
        '**** TODO [#A] COMMENT Title :tag:a2%:',
      ]) {
        expect(grammar.parse(valid).isSuccess, true);
      }
    });
    test('example document', () {
      final doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
      expect(grammar.parse(doc).isSuccess, true);
      final parsed = parser.parse(doc);
      expect(parsed.isSuccess, true);
      final List values = parsed.value;
      final OrgContent firstContent = values[0];
      final OrgPlainText text = firstContent.children[0];
      expect(text.content, 'An introduction.\n\n');
      final List sections = values[1];
      final topSection = sections[0];
      expect(topSection.headline.title.children[0].content, 'A Headline');
      expect(topSection.children.length, 2);
    });
  });

  group('content grammar', () {
    final grammar = OrgContentGrammar();
    final parser = OrgContentParser();
    test('content parsing', () {
      final result = grammar.parse('''foo bar
biz baz''');
      expect(result.value, ['foo bar\nbiz baz']);
    });
    test('link grammar', () {
      final result = grammar.parse('''[[http://example.com][example]]''');
      expect(result.value, [
        [
          '[',
          [
            '[',
            ['http://example.com', null],
            ']'
          ],
          ['[', 'example', ']'],
          ']'
        ]
      ]);
    });
    test('complex content', () {
      final result =
          grammar.parse('''go to [[http://example.com][example]] for *fun*,
maybe''');
      expect(result.value, [
        'go to ',
        [
          '[',
          [
            '[',
            ['http://example.com', null],
            ']'
          ],
          ['[', 'example', ']'],
          ']'
        ],
        ' for ',
        ['*', 'fun', '*'],
        ',\n'
            'maybe'
      ]);
    });
    test('markup', () {
      var result = grammar.parse('''a/b
c/d''');
      expect(result.value, ['a/b\nc/d'], reason: 'bad pre/post chars');
      result = grammar.parse('''a /b
c/d''');
      expect(result.value, ['a /b\nc/d'], reason: 'bad post char');
      result = grammar.parse('''a/b
c/ d''');
      expect(result.value, ['a/b\nc/ d'], reason: 'bad pre char');
      result = grammar.parse('/a/');
      expect(result.value, [
        ['/', 'a', '/']
      ]);
      result = grammar.parse('/abc/');
      expect(result.value, [
        ['/', 'abc', '/']
      ]);
      result = grammar.parse('/a b/');
      expect(result.value, [
        ['/', 'a b', '/']
      ]);
      result = grammar.parse('//');
      expect(result.value, ['//'], reason: 'body is required');
    });
    test('meta', () {
      var result = grammar.parse('''#+blah
foo''');
      expect(result.value, ['#+blah', '\nfoo']);
      result = grammar.parse('''   #+blah
foo''');
      expect(result.value, ['   #+blah', '\nfoo']);
      result = grammar.parse('''a   #+blah
foo''');
      expect(result.value, ['a   #+blah\nfoo'],
          reason: 'only leading space is allowed');
    });
    test('links', () {
      var result = grammar.parse('a http://example.com b');
      expect(result.value, ['a ', 'http://example.com', ' b']);
      result = grammar.parse('a https://example.com b');
      expect(result.value, ['a ', 'https://example.com', ' b']);
      result = grammar.parse('a [[foo][bar]] b');
      expect(result.value, [
        'a ',
        [
          '[',
          [
            '[',
            ['foo', null],
            ']'
          ],
          ['[', 'bar', ']'],
          ']'
        ],
        ' b'
      ]);
      result = grammar.parse('a [[foo::1][bar]] b');
      expect(result.value, [
        'a ',
        [
          '[',
          [
            '[',
            [
              'foo',
              ['::', '1']
            ],
            ']'
          ],
          ['[', 'bar', ']'],
          ']'
        ],
        ' b'
      ]);
      result = parser.parse('[[foo::1][bar]]');
      OrgContent content = result.value;
      OrgLink link = content.children[0];
      expect(link.description, 'bar');
      expect(link.location, 'foo::1');
      result = parser.parse('[[foo::"[1]"][bar]]');
      content = result.value;
      link = content.children[0];
      expect(link.description, 'bar');
      expect(link.location, 'foo::"[1]"');
    });
    test('blocks', () {
      var result = grammar.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src''');
      expect(result.value, [
        [
          ['', '#+begin_src', ' sh\n'],
          '  echo \'foo\'\n  rm bar',
          ['\n', '#+end_src', '']
        ]
      ]);
      result = grammar.parse('''#+BEGIN_SRC sh
  echo 'foo'
  rm bar
#+EnD_sRC
''');
      expect(result.value, [
        [
          ['', '#+BEGIN_SRC', ' sh\n'],
          '  echo \'foo\'\n  rm bar',
          ['\n', '#+EnD_sRC', ''],
        ],
        '\n'
      ]);
      result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
      OrgBlock block = result.value.children[0];
      OrgMarkup body = block.body;
      expect(block.header, '#+begin_src sh');
      expect(body.content, '  echo \'foo\'\n  rm bar');
      expect(block.footer, '#+end_src');
    });
    test('greater blocks', () {
      var result = grammar.parse('''#+begin_quote
  foo *bar*
#+end_quote''');
      expect(result.value, [
        [
          ['', '#+begin_quote', '\n'],
          '  foo *bar*',
          ['\n', '#+end_quote', '']
        ]
      ]);
      result = grammar.parse('''#+BEGIN_QUOTE
  foo /bar/
#+EnD_qUOtE
''');
      expect(result.value, [
        [
          ['', '#+BEGIN_QUOTE', '\n'],
          '  foo /bar/',
          ['\n', '#+EnD_qUOtE', '']
        ],
        '\n'
      ]);
      result = parser.parse('''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''');
      OrgBlock block = result.value.children[0];
      expect(block.header, '#+begin_center');
      OrgContent body = block.body;
      OrgPlainText child = body.children[0];
      expect(child.content, '  foo ');
      expect(block.footer, '#+end_center');
    });
  });
}
