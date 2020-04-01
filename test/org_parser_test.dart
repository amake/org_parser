import 'dart:io';

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
    test('parse a complex header', () {
      var result = grammar.parse('** TODO [#A] Title foo bar :biz:baz:');
      expect(result.value, [
        null,
        [
          [
            [
              '**',
              'TODO',
              ['[#', 'A', ']'],
              'Title foo bar ',
              [
                ':',
                ['biz', 'baz'],
                ':'
              ]
            ],
            null
          ]
        ]
      ]);
      result = parser.parse('** TODO [#A] Title foo bar :biz:baz:');
      final List values = result.value;
      final List<OrgSection> sections = values[1];
      final OrgPlainText title = sections[0].headline.title.children[0];
      expect(title.content, 'Title foo bar ');
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
      const doc = '''An introduction.

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
      var result = grammar.parse('[[http://example.com][example]]');
      expect(result.value, [
        [
          '[',
          ['[', 'http://example.com', ']'],
          ['[', 'example', ']'],
          ']'
        ]
      ]);
      result = grammar.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      expect(result.value, [
        [
          '[',
          ['[', '*[wtf] what?', ']'],
          ['[', '[lots][of][boxes]', ']'],
          ']'
        ]
      ]);
      result = parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
      final OrgContent content = result.value;
      final OrgLink link = content.children[0];
      expect(link.location, '*[wtf] what?');
      expect(link.description, '[lots][of][boxes]');
    });
    test('complex content', () {
      final result =
          grammar.parse('''go to [[http://example.com][example]] for *fun*,
maybe''');
      expect(result.value, [
        'go to ',
        [
          '[',
          ['[', 'http://example.com', ']'],
          ['[', 'example', ']'],
          ']'
        ],
        ' for ',
        ['*', 'fun', '*'],
        ',\nmaybe'
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
      result = grammar.parse('~,~');
      expect(result.value, [
        ['~', ',', '~']
      ]);
      result = grammar.parse("~'~");
      expect(result.value, [
        ['~', "'", '~']
      ]);
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
          ['[', 'foo', ']'],
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
          ['[', 'foo::1', ']'],
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
      result = parser.parse('[[foo::"\\[1\\]"][bar]]');
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
          '',
          ['#+begin_src', ' sh\n'],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+end_src', '']
        ]
      ]);
      result = grammar.parse('''#+BEGIN_SRC sh
  echo 'foo'
  rm bar
#+EnD_sRC
''');
      expect(result.value, [
        [
          '',
          ['#+BEGIN_SRC', ' sh\n'],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+EnD_sRC', '\n']
        ]
      ]);
      result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
      final OrgBlock block = result.value.children[0];
      final OrgMarkup body = block.body;
      expect(block.header, '#+begin_src sh\n');
      expect(body.content, '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_src\n');
    });
    test('greater blocks', () {
      var result = grammar.parse('''#+begin_quote
  foo *bar*
#+end_quote''');
      expect(result.value, [
        [
          '',
          ['#+begin_quote', '\n'],
          [
            '  foo ',
            ['*', 'bar', '*'],
            '\n'
          ],
          ['', '#+end_quote', '']
        ]
      ]);
      result = grammar.parse('''#+BEGIN_QUOTE
  foo /bar/
#+EnD_qUOtE
''');
      expect(result.value, [
        [
          '',
          ['#+BEGIN_QUOTE', '\n'],
          [
            '  foo ',
            ['/', 'bar', '/'],
            '\n'
          ],
          ['', '#+EnD_qUOtE', '\n']
        ],
      ]);
      result = parser.parse('''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''');
      final OrgBlock block = result.value.children[0];
      expect(block.header, '#+begin_center\n');
      final OrgContent body = block.body;
      final OrgPlainText child = body.children[0];
      expect(child.content, '  foo ');
      expect(block.footer, '#+end_center\n');
    });
    test('tables', () {
      var result = grammar.parse('''  | foo | bar | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
      expect(result.value, [
        [
          [
            '  ',
            '|',
            [
              [
                ' ',
                ['foo'],
                ' |'
              ],
              [
                ' ',
                ['bar'],
                ' |'
              ],
              [
                ' ',
                ['baz'],
                ' |'
              ]
            ],
            '\n'
          ],
          ['  ', '|-----+-----+-----|\n'],
          [
            '  ',
            '|',
            [
              [
                '   ',
                ['1'],
                ' |'
              ],
              [
                '   ',
                ['2'],
                ' |'
              ],
              [
                '   ',
                ['3'],
                ' |'
              ]
            ],
            '\n'
          ]
        ]
      ]);
      result = parser.parse('''  | foo | *bar* | baz |
  |-----+-----+-----|
  |   1 |   2 |   3 |
''');
      final OrgTable table = result.value.children[0];
      final OrgTableCellRow row0 = table.rows[0];
      final OrgPlainText row0Cell0 = row0.cells[0].children[0];
      expect(row0Cell0.content, 'foo');
      final OrgMarkup row0Cell1 = row0.cells[1].children[0];
      expect(row0Cell1.content, '*bar*');
      expect(row0.cells.length, 3);
      final OrgTableDividerRow row1 = table.rows[1];
      expect(row1 != null, true);
      final OrgTableCellRow row2 = table.rows[2];
      expect(row2.cells.length, 3);
    });
    test('timestamps', () {
      var result = grammar.parse('''<2020-03-12 Wed>''');
      expect(result.value, [
        [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          null,
          [],
          '>'
        ]
      ]);
      result = grammar.parse('''<2020-03-12 Wed 8:34>''');
      expect(result.value, [
        [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [],
          '>'
        ]
      ]);
      result = grammar.parse('''<2020-03-12 Wed 8:34 +1w>''');
      expect(result.value, [
        [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [
            ['+', '1', 'w']
          ],
          '>'
        ]
      ]);
      result = grammar.parse('''<2020-03-12 Wed 8:34 +1w --2d>''');
      expect(result.value, [
        [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [
            ['+', '1', 'w'],
            ['--', '2', 'd']
          ],
          '>'
        ]
      ]);
      result = grammar.parse('''[2020-03-12 Wed 18:34 .+1w --12d]''');
      expect(result.value, [
        [
          '[',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['18', ':', '34'],
          [
            ['.+', '1', 'w'],
            ['--', '12', 'd']
          ],
          ']'
        ]
      ]);
      result = grammar.parse('''[2020-03-12 Wed 18:34-19:35 .+1w --12d]''');
      expect(result.value, [
        [
          '[',
          ['2020', '-', '03', '-', '12', 'Wed'],
          [
            ['18', ':', '34'],
            '-',
            ['19', ':', '35']
          ],
          [
            ['.+', '1', 'w'],
            ['--', '12', 'd']
          ],
          ']'
        ]
      ]);
      result = grammar.parse(
          '''[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]''');
      expect(result.value, [
        [
          [
            '[',
            ['2020', '-', '03', '-', '11', 'Wed'],
            ['18', ':', '34'],
            [
              ['.+', '1', 'w'],
              ['--', '12', 'd']
            ],
            ']'
          ],
          '--',
          [
            '[',
            ['2020', '-', '03', '-', '12', 'Wed'],
            ['18', ':', '34'],
            [
              ['.+', '1', 'w'],
              ['--', '12', 'd']
            ],
            ']'
          ]
        ]
      ]);
      result = grammar.parse('''<%%(what (the (f)))>''');
      expect(result.value, [
        [
          '<%%',
          [
            '(',
            [
              'what',
              [
                '(',
                [
                  'the',
                  [
                    '(',
                    ['f'],
                    ')'
                  ]
                ],
                ')'
              ]
            ],
            ')'
          ],
          '>'
        ]
      ]);
      result = grammar.parse('''<%%(what (the (f))>''');
      expect(result.value, ['<%%(what (the (f))>'], reason: 'Invalid sexp');
      result = grammar.parse('''[2020-03-11 Wed 18:34:56 .+1w --12d]''');
      expect(result.value, ['[2020-03-11 Wed 18:34:56 .+1w --12d]'],
          reason: 'Seconds not supported');
    });
    test('fixed-width area', () {
      var result = grammar.parse('  : foo');
      expect(result.value, [
        [
          ['  ', ': ', 'foo']
        ]
      ]);
      result = grammar.parse('''  : foo
  : bar''');
      expect(result.value, [
        [
          ['  ', ': ', 'foo\n'],
          ['  ', ': ', 'bar']
        ]
      ]);
    });
    test('lists', () {
      var result = grammar.parse('- foo');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              ['foo']
            ]
          ]
        ]
      ]);
      result = grammar.parse('''- foo
  - bar''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              [
                'foo\n',
                [
                  [
                    '  ',
                    [
                      '- ',
                      null,
                      null,
                      ['bar']
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]);
      result = grammar.parse('''- foo

  bar''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              ['foo\n\n  bar']
            ]
          ]
        ]
      ]);
      result = grammar.parse('  - foo\n'
          ' \n'
          '    bar');
      expect(result.value, [
        [
          [
            '  ',
            [
              '- ',
              null,
              null,
              ['foo\n \n    bar']
            ]
          ]
        ]
      ]);
      result = grammar.parse('''- foo


  bar''');
      expect(result.value, [
        [
          [
            '',
            [
              '- ',
              null,
              null,
              ['foo\n\n']
            ]
          ]
        ],
        '\n  bar'
      ]);
      result = grammar.parse('''30. [@30] foo
   - bar :: baz
     blah
   - [ ] *bazinga*''');
      expect(result.value, [
        [
          [
            '',
            [
              ['30', '.', ' '],
              ['[@', '30', ']'],
              null,
              [
                'foo\n',
                [
                  [
                    '   ',
                    [
                      '- ',
                      null,
                      ['bar', ' :: '],
                      ['baz\n     blah\n']
                    ]
                  ],
                  [
                    '   ',
                    [
                      '- ',
                      ['[', ' ', ']'],
                      null,
                      [
                        ['*', 'bazinga', '*']
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]);
    });
  });
  test('complex document', () {
    final result =
        OrgParser().parse(File('test/org-syntax.org').readAsStringSync());
    expect(result.isSuccess, true);
  });
}
