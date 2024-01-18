// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

import '../matchers.dart';

void main() {
  group('headline', () {
    final grammarDefinion = OrgGrammarDefinition();
    final parser = grammarDefinion.buildFrom(grammarDefinion.headline());
    test('parse a headline', () {
      final result = parser.parse('* Title');
      expect(
        result.value,
        [
          ['*', ' '],
          null,
          null,
          'Title',
          null,
          null
        ],
      );
    });
    test('parse almost-a-header', () {
      final result = parser.parse('**');
      expect(result, isA<Failure>());
    });
    test('parse just an empty header', () {
      final result = parser.parse('* ');
      expect(
        result.value,
        [
          ['*', ' '],
          null,
          null,
          null,
          null,
          null
        ],
      );
    });
    test('parse a todo header', () {
      final result = parser.parse('* TODO Title');
      expect(
        result.value,
        [
          ['*', ' '],
          ['TODO', ' '],
          null,
          'Title',
          null,
          null
        ],
      );
    });
    test('parse a complex header', () {
      final result = parser.parse('** TODO [#A] Title foo bar :biz:baz:');
      expect(result.value, [
        ['**', ' '],
        ['TODO', ' '],
        ['[#', 'A', '] '],
        'Title foo bar',
        [
          ' :',
          isSeparatedList<dynamic, String>(elements: [
            'biz',
            'baz',
          ], separators: [
            ':'
          ]),
          ':',
          null,
        ],
        null
      ]);
    });
  });
  group('structural grammar', () {
    final grammar = OrgGrammarDefinition().build();
    test('parse content', () {
      final result = grammar.parse('''foo
bar
''');
      expect(result.value, ['foo\nbar\n', []]);
    });
    test('parse an empty header before a regular header', () {
      final result = grammar.parse('''**${' '}
* foo''');
      expect(result.value, [
        null,
        [
          [
            [
              ['**', ' '],
              null,
              null,
              null,
              null,
              '\n',
            ],
            null,
          ],
          [
            [
              ['*', ' '],
              null,
              null,
              'foo',
              null,
              null
            ],
            null
          ]
        ]
      ]);
    });
    test('parse an almost-header before content', () {
      final result = grammar.parse('''*
foo''');
      expect(result.value, ['*\nfoo', []]);
    });
    test('parse a section', () {
      final result = grammar.parse('''* Title
  Content1
  Content2''');
      expect(result.value, [
        null,
        [
          [
            [
              ['*', ' '],
              null,
              null,
              'Title',
              null,
              '\n'
            ],
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
        expect(grammar.parse(valid), isA<Success<dynamic>>());
      }
    });
  });

  group('content grammar parts', () {
    final grammarDefinition = OrgContentGrammarDefinition();
    Parser buildSpecific(Parser Function() start) {
      return grammarDefinition.buildFrom(start()).end();
    }

    group('paragraph', () {
      final parser = buildSpecific(grammarDefinition.paragraph);
      test('with line break', () {
        final result = parser.parse('''foo bar
biz baz''');
        expect(result.value, [
          '',
          ['foo bar\nbiz baz']
        ]);
      });
      test('with inline objects', () {
        final result =
            parser.parse('''go to [[http://example.com][example]] for *fun*,
maybe''');
        expect(result.value, [
          '',
          [
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
          ]
        ]);
      });
    });
    group('link', () {
      final parser = buildSpecific(grammarDefinition.link);
      test('with description', () {
        final result = parser.parse('[[http://example.com][example]]');
        expect(result.value, [
          '[',
          ['[', 'http://example.com', ']'],
          ['[', 'example', ']'],
          ']'
        ]);
      });
      test('brackets in location', () {
        final result =
            parser.parse('[[*\\[wtf\\] what?][[lots][of][boxes]\u200b]]');
        expect(result.value, [
          '[',
          ['[', '*[wtf] what?', ']'],
          ['[', '[lots][of][boxes]', ']'],
          ']'
        ]);
      });
      test('bare HTTP URL', () {
        final result = parser.parse('http://example.com');
        expect(result.value, 'http://example.com');
      });
      test('bare HTTPS URL', () {
        final result = parser.parse('https://example.com');
        expect(result.value, 'https://example.com');
      });
      test('bare file URL', () {
        final result = parser.parse('file:example.txt');
        expect(result.value, 'file:example.txt');
      });
      test('bare attachment URL', () {
        final result = parser.parse('attachment:example.txt');
        expect(result.value, 'attachment:example.txt');
      });
      test('arbitrary protocol', () {
        final result = parser.parse('foobar://example.com');
        expect(result, isA<Failure>());
      });
    });
    group('markup', () {
      final parser = buildSpecific(grammarDefinition.markups);
      test('bad pre and post chars', () {
        final result = parser.parse('''a/b
c/d''');
        expect(result, isA<Failure>());
      });
      test('bad post char', () {
        final result = parser.parse('''a /b
c/d''');
        expect(result, isA<Failure>());
      });
      test('bad pre char', () {
        final result = parser.parse('''a/b
c/ d''');
        expect(result, isA<Failure>());
      });
      test('single char', () {
        final result = parser.parse('/a/');
        expect(result.value, ['/', 'a', '/']);
      });
      test('single word', () {
        final result = parser.parse('/abc/');
        expect(result.value, ['/', 'abc', '/']);
      });
      test('multiple words', () {
        final result = parser.parse('/a b/');
        expect(result.value, ['/', 'a b', '/']);
      });
      test('empty', () {
        final result = parser.parse('//');
        expect(result, isA<Failure>());
      });
      test('single comma', () {
        final result = parser.parse('~,~');
        expect(result.value, ['~', ',', '~']);
      });
      test('single apostrophe', () {
        final result = parser.parse("~'~");
        expect(result.value, ['~', "'", '~']);
      });
      test('with delimiters inside', () {
        final result = parser.parse('=+LEVEL=3+boss-TODO​="DONE"=');
        expect(result.value, ['=', '+LEVEL=3+boss-TODO​="DONE"', '=']);
      });
      test('with line break', () {
        final result = parser.parse('''+foo
bar+''');
        expect(result.value, ['+', 'foo\nbar', '+']);
      });
      test('too many line breaks', () {
        final result = parser.parse('''+foo

bar+''');
        expect(result, isA<Failure>());
      });
    });
    group('macro reference', () {
      final parser = buildSpecific(grammarDefinition.macroReference);
      test('with args', () {
        final result = parser.parse('{{{name(arg1, arg2)}}}');
        expect(result.value, ['{{{', 'name', '(arg1, arg2)', '}}}']);
      });
      test('simple', () {
        final result = parser.parse('{{{foobar}}}');
        expect(result.value, ['{{{', 'foobar', '', '}}}']);
      });
      test('empty', () {
        final result = parser.parse('{{{}}}');
        expect(result, isA<Failure>());
      });
      test('invalid key', () {
        final result = parser.parse('{{{0abc}}}');
        expect(result, isA<Failure>());
      });
    });
    group('affiliated keyword', () {
      final parser = buildSpecific(grammarDefinition.affiliatedKeyword);
      test('indented', () {
        final result = parser.parse('  #+blah');
        expect(result.value, ['  ', '#+blah', '']);
      });
      test('not at beginning of line', () {
        final result = parser.parse('''a   #+blah''');
        expect(result, isA<Failure>());
      });
    });
    group('block', () {
      final parser = buildSpecific(grammarDefinition.block);
      test('lower case', () {
        final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src''');
        expect(result.value, [
          '',
          [
            [
              '#+begin_src',
              [' ', 'sh'],
              '\n'
            ],
            '  echo \'foo\'\n  rm bar\n',
            ['', '#+end_src']
          ],
          ''
        ]);
      });
      test('mismatched case', () {
        final result = parser.parse('''#+BEGIN_SRC sh
  echo 'foo'
  rm bar
#+EnD_sRC
''');
        expect(result.value, [
          '',
          [
            [
              '#+BEGIN_SRC',
              [' ', 'sh'],
              '\n'
            ],
            '  echo \'foo\'\n  rm bar\n',
            ['', '#+EnD_sRC']
          ],
          '\n'
        ]);
      });
      test('no language', () {
        final result = parser.parse('''#+begin_src
  echo 'foo'
  rm bar
#+end_src
''');
        expect(result.value, [
          '',
          [
            ['#+begin_src', null, '\n'],
            '  echo \'foo\'\n  rm bar\n',
            ['', '#+end_src']
          ],
          '\n'
        ]);
      });
    });
    group('greater block', () {
      final parser = buildSpecific(grammarDefinition.greaterBlock);
      test('lower case', () {
        final result = parser.parse('''#+begin_quote
  foo *bar*
#+end_quote''');
        expect(result.value, [
          '',
          [
            ['#+begin_quote', '\n'],
            [
              '  foo ',
              ['*', 'bar', '*'],
              '\n'
            ],
            ['', '#+end_quote']
          ],
          ''
        ]);
      });
      test('mismatched case', () {
        final result = parser.parse('''#+BEGIN_QUOTE
  foo /bar/
#+EnD_qUOtE
''');
        expect(result.value, [
          '',
          [
            ['#+BEGIN_QUOTE', '\n'],
            [
              '  foo ',
              ['/', 'bar', '/'],
              '\n'
            ],
            ['', '#+EnD_qUOtE']
          ],
          '\n'
        ]);
      });
    });
    test('table', () {
      final parser = buildSpecific(grammarDefinition.table);
      final result = parser.parse('''  | foo | bar | baz |
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
          ['  ', '|-----+-----+-----|', '\n'],
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
        ],
        ''
      ]);
    });
    group('timestamps', () {
      final parser = buildSpecific(grammarDefinition.timestamp);
      test('date', () {
        final result = parser.parse('''<2020-03-12 Wed>''');
        expect(result.value, [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          null,
          [],
          '>'
        ]);
      });
      test('date and time', () {
        final result = parser.parse('''<2020-03-12 Wed 8:34>''');
        expect(result.value, [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [],
          '>'
        ]);
      });
      test('with repeater', () {
        final result = parser.parse('''<2020-03-12 Wed 8:34 +1w>''');
        expect(result.value, [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [
            ['+', '1', 'w']
          ],
          '>'
        ]);
      });
      test('with multiple repeaters', () {
        final result = parser.parse('''<2020-03-12 Wed 8:34 +1w --2d>''');
        expect(result.value, [
          '<',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['8', ':', '34'],
          [
            ['+', '1', 'w'],
            ['--', '2', 'd']
          ],
          '>'
        ]);
      });
      test('inactive', () {
        final result = parser.parse('''[2020-03-12 Wed 18:34 .+1w --12d]''');
        expect(result.value, [
          '[',
          ['2020', '-', '03', '-', '12', 'Wed'],
          ['18', ':', '34'],
          [
            ['.+', '1', 'w'],
            ['--', '12', 'd']
          ],
          ']'
        ]);
      });
      test('time range', () {
        final result =
            parser.parse('''[2020-03-12 Wed 18:34-19:35 .+1w --12d]''');
        expect(result.value, [
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
        ]);
      });
      test('date range', () {
        final result = parser.parse(
            '''[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]''');
        expect(result.value, [
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
        ]);
      });
      test('sexp', () {
        final result = parser.parse('''<%%(what (the (f)))>''');
        expect(result.value, [
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
        ]);
      });
      test('invalid sexp', () {
        final result = parser.parse('''<%%(what (the (f))>''');
        expect(result, isA<Failure>());
      });
      test('with seconds', () {
        final result = parser.parse('''[2020-03-11 Wed 18:34:56 .+1w --12d]''');
        expect(result, isA<Failure>(), reason: 'Seconds not supported');
      });
    });
    group('fixed-width area', () {
      final parser = buildSpecific(grammarDefinition.fixedWidthArea);
      test('single line', () {
        final result = parser.parse('  : foo');
        expect(result.value, [
          [
            ['  ', ': ', 'foo']
          ],
          ''
        ]);
      });
      test('multiple lines', () {
        final result = parser.parse('''  : foo
  : bar''');
        expect(result.value, [
          [
            ['  ', ': ', 'foo\n'],
            ['  ', ': ', 'bar']
          ],
          ''
        ]);
      });
    });
    group('list', () {
      final parser = buildSpecific(grammarDefinition.list);
      test('single line', () {
        final result = parser.parse('- foo');
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
          ],
          ''
        ]);
      });
      test('multiple lines', () {
        final result = parser.parse('''- foo
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
                      [
                        '  ',
                        [
                          '- ',
                          null,
                          null,
                          ['bar']
                        ]
                      ]
                    ],
                    ''
                  ]
                ]
              ]
            ]
          ],
          ''
        ]);
      });
      test('multiline item', () {
        final result = parser.parse('''- foo

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
          ],
          ''
        ]);
      });
      test('multiline item with eol white space', () {
        final result = parser.parse(
          '  - foo\n'
          ' \n'
          '    bar',
        );
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
          ],
          ''
        ]);
      });
      test('complex', () {
        final result = parser.parse('''30. [@30] foo
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
                      [
                        '   ',
                        [
                          '- ',
                          null,
                          [
                            ['bar'],
                            ' :: '
                          ],
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
                    ],
                    ''
                  ]
                ]
              ]
            ]
          ],
          ''
        ]);
      });
      test('item with block', () {
        final result = parser.parse('''- foo
  #+begin_src sh
    echo bar
  #+end_src''');
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
                    '  ',
                    [
                      [
                        '#+begin_src',
                        [' ', 'sh'],
                        '\n'
                      ],
                      '    echo bar\n',
                      ['  ', '#+end_src']
                    ],
                    ''
                  ]
                ]
              ]
            ]
          ],
          ''
        ]);
      });
      test('with tag', () {
        final result = parser.parse('- ~foo~ ::');
        expect(result.value, [
          [
            [
              '',
              [
                '- ',
                null,
                [
                  [
                    ['~', 'foo', '~']
                  ],
                  ' ::'
                ],
                []
              ]
            ]
          ],
          ''
        ]);
      });
    });
    test('planning line', () {
      final parser = buildSpecific(grammarDefinition.planningLine);
      final result = parser.parse(
          'CLOCK: [2021-02-16 Tue 21:40]--[2021-02-16 Tue 21:40] =>  0:00');
      expect(result.value, [
        '',
        [
          'CLOCK:',
          [
            ' ',
            [
              [
                '[',
                ['2021', '-', '02', '-', '16', 'Tue'],
                ['21', ':', '40'],
                [],
                ']'
              ],
              '--',
              [
                '[',
                ['2021', '-', '02', '-', '16', 'Tue'],
                ['21', ':', '40'],
                [],
                ']'
              ]
            ],
            ' =>  0:00'
          ]
        ],
        ''
      ]);
    });
    group('drawer', () {
      final parser = buildSpecific(grammarDefinition.drawer);
      test('empty', () {
        final result = parser.parse(''':foo:
:end:''');
        expect(result.value, [
          '',
          [
            [':', 'foo', ':', '\n'],
            [],
            ['', ':end:']
          ],
          ''
        ]);
      });
      test('single property', () {
        final result = parser.parse('''  :foo:
  :bar: baz
  :end:

''');
        expect(result.value, [
          '  ',
          [
            [':', 'foo', ':', '\n'],
            [
              [
                '  ',
                [':', 'bar', ':'],
                ' baz',
                '\n'
              ]
            ],
            ['  ', ':end:']
          ],
          '\n\n'
        ]);
      });
      test('planning line', () {
        final result = parser.parse(''':LOGBOOK:
CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49
:END:
''');
        expect(result.value, [
          '',
          [
            [':', 'LOGBOOK', ':', '\n'],
            [
              [
                '',
                [
                  'CLOCK:',
                  [
                    ' ',
                    [
                      [
                        '[',
                        ['2021', '-', '01', '-', '23', 'Sat'],
                        ['09', ':', '30'],
                        [],
                        ']'
                      ],
                      '--',
                      [
                        '[',
                        ['2021', '-', '01', '-', '23', 'Sat'],
                        ['10', ':', '19'],
                        [],
                        ']'
                      ]
                    ],
                    ' =>  0:49'
                  ]
                ],
                '\n'
              ]
            ],
            ['', ':END:']
          ],
          '\n'
        ]);
      });
      test('nested', () {
        final result = parser.parse(''':foo:
:bar:
:end:
:end:''');
        expect(result, isA<Failure>(),
            reason: 'Nested drawer disallowed; the trailing ":end:" is '
                'a separate paragraph, which fails the drawer-specific parser');
      });
    });
    group('property', () {
      final parser = buildSpecific(grammarDefinition.property);
      test('simple', () {
        final result = parser.parse(':foo: bar');
        expect(result.value, [
          '',
          [':', 'foo', ':'],
          ' bar',
          ''
        ]);
      });
      test('missing value', () {
        final result = parser.parse(':foo:');
        expect(result, isA<Failure>());
      });
      test('missing delimiter', () {
        final result = parser.parse(':foo:blah');
        expect(result, isA<Failure>(), reason: 'Delimiting space required');
      });
      test('line break', () {
        final result = parser.parse(''':foo:
bar''');
        expect(result, isA<Failure>(), reason: 'Value must be on same line');
      });
    });
    group('footnote', () {
      final parser = buildSpecific(grammarDefinition.footnote);
      test('simple', () {
        final result = parser.parse('[fn:1] foo *bar*');
        expect(result.value, [
          ['[fn:', '1', ']'],
          [
            ' foo ',
            ['*', 'bar', '*']
          ],
          ''
        ]);
      });
      test('multiple lines', () {
        final result = parser.parse('''[fn:1] foo *bar*
baz bazinga

''');
        expect(result.value, [
          ['[fn:', '1', ']'],
          [
            ' foo ',
            ['*', 'bar', '*'],
            '\nbaz bazinga\n\n'
          ],
          ''
        ]);
      });
      test('indented', () {
        final result = parser.parse(' [fn:1] foo *bar*');
        expect(result, isA<Failure>(), reason: 'Indent not allowed');
      });
      test('complex reference', () {
        final result = parser.parse('[fn:1: blah] foo *bar*');
        expect(result, isA<Failure>(),
            reason: 'Only simple references allowed');
      });
    });
    group('footnote reference', () {
      final parser = buildSpecific(grammarDefinition.footnoteReference);
      test('numeric', () {
        final result = parser.parse('[fn:1]');
        expect(result.value, ['[fn:', '1', ']']);
      });
      test('alphanumeric', () {
        final result = parser.parse('[fn:abc123]');
        expect(result.value, ['[fn:', 'abc123', ']']);
      });
      test('with definition', () {
        final result = parser.parse('[fn:abc123: who what why]');
        expect(result.value, [
          '[fn:',
          'abc123',
          ':',
          [' who what why'],
          ']'
        ]);
      });
      test('with definition with formatting', () {
        final result = parser.parse('[fn:abc123: who *what* why]');
        expect(result.value, [
          '[fn:',
          'abc123',
          ':',
          [
            ' who ',
            ['*', 'what', '*'],
            ' why'
          ],
          ']'
        ]);
      });
    });
    group('entity', () {
      final parser = buildSpecific(grammarDefinition.entity);
      test('there4', () {
        final result = parser.parse(r'\there4');
        expect(result.value, [r'\', 'there4', '']);
      });
      test('sup valid', () {
        final result = parser.parse(r'\sup1');
        expect(result.value, [r'\', 'sup1', '']);
      });
      test('sup invalid', () {
        final result = parser.parse(r'\sup5');
        expect(result, isA<Failure>());
      });
      test('valid frac', () {
        final result = parser.parse(r'\frac12');
        expect(result.value, [r'\', 'frac12', '']);
      });
      test('invalid frac', () {
        final result = parser.parse(r'\frac15');
        expect(result, isA<Failure>());
      });
      test('arbitrary alphabetical', () {
        final result = parser.parse(r'\foobar');
        expect(result.value, [r'\', 'foobar', '']);
      });
      test('arbitrary alphanumeric', () {
        final result = parser.parse(r'\foobar2');
        expect(result, isA<Failure>());
      });
      test('with terminator', () {
        final result = parser.parse(r'\foobar{}');
        expect(result.value, [r'\', 'foobar', '{}']);
      });
    });

    group('local variables', () {
      final parser = buildSpecific(grammarDefinition.localVariables);
      test('simple', () {
        final result = parser.parse('''# Local Variables:
# foo: bar
# End: ''');
        expect(result.value, [
          '# Local Variables:\n',
          [
            ['# ', 'foo: bar', '\n']
          ],
          '# End: '
        ]);
      });
      test('with suffix', () {
        final result = parser.parse('''# Local Variables: #
# foo: bar #
# End: #''');
        expect(result.value, [
          '# Local Variables: #\n',
          [
            ['# ', 'foo: bar ', '#\n']
          ],
          '# End: #'
        ]);
      });
      test('bad prefix', () {
        final result = parser.parse('''# Local Variables:
## foo: bar
# End:''');
        expect(result, isA<Failure>());
      });
      test('bad suffix', () {
        final result = parser.parse('''/* Local Variables: */
/* foo: bar */
/* End: **/''');
        expect(result, isA<Failure>());
      });
    });

    group('PGP block', () {
      final parser = buildSpecific(grammarDefinition.pgpBlock);
      test('simple', () {
        final result = parser.parse('''-----BEGIN PGP MESSAGE-----

jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
=chda
-----END PGP MESSAGE-----
''');
        expect(result.value, [
          '',
          '-----BEGIN PGP MESSAGE-----',
          '\n\n'
              'jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
              'X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
              '=chda\n',
          '-----END PGP MESSAGE-----',
          '\n'
        ]);
      });
      test('indented', () {
        final result = parser.parse('''   -----BEGIN PGP MESSAGE-----

   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O
   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=
   =chda
   -----END PGP MESSAGE-----
''');
        expect(result.value, [
          '   ',
          '-----BEGIN PGP MESSAGE-----',
          '\n\n'
              '   jA0ECQMIP3AfqImNg7Xy0j8BBJmT8GSO3VIzObhKP4d6rcH3SdhUpI0dnFpg0y+O\n'
              '   X0q9CWVysb7ljRYEkpIbFpdKeCtLFBXSJJdCxfKewKY=\n'
              '   =chda\n'
              '   ',
          '-----END PGP MESSAGE-----',
          '\n'
        ]);
      });
    });
    group('Comment', () {
      final parser = buildSpecific(grammarDefinition.comment);
      test('simple', () {
        final result = parser.parse('''# foo bar''');
        expect(result.value, ['', '# ', 'foo bar']);
      });
      test('indented', () {
        final result = parser.parse('''   # foo bar''');
        expect(result.value, ['   ', '# ', 'foo bar']);
      });
    });
  });

  group('content grammar complete', () {
    final parser = OrgContentGrammarDefinition().build();
    test('paragraph', () {
      final result = parser.parse('''foo bar *biz*

  #+begin_quote
    blah
  #+end_quote
bazinga''');
      expect(result.value, [
        [
          '',
          [
            'foo bar ',
            ['*', 'biz', '*'],
            '\n\n'
          ]
        ],
        [
          '  ',
          [
            ['#+begin_quote', '\n'],
            ['    blah\n'],
            ['  ', '#+end_quote']
          ],
          '\n'
        ],
        [
          '',
          ['bazinga']
        ]
      ]);
    });
    group('link', () {
      test('bare HTTP URL', () {
        final result = parser.parse('a http://example.com b');
        expect(result.value, [
          [
            '',
            ['a ', 'http://example.com', ' b']
          ]
        ]);
      });
      test('bare HTTPS URL', () {
        final result = parser.parse('a https://example.com b');
        expect(result.value, [
          [
            '',
            ['a ', 'https://example.com', ' b']
          ]
        ]);
      });
      test('with description', () {
        final result = parser.parse('a [[foo][bar]] b');
        expect(result.value, [
          [
            '',
            [
              'a ',
              [
                '[',
                ['[', 'foo', ']'],
                ['[', 'bar', ']'],
                ']'
              ],
              ' b'
            ]
          ]
        ]);
      });
      test('with line number', () {
        final result = parser.parse('a [[foo::1][bar]] b');
        expect(result.value, [
          [
            '',
            [
              'a ',
              [
                '[',
                ['[', 'foo::1', ']'],
                ['[', 'bar', ']'],
                ']'
              ],
              ' b'
            ]
          ]
        ]);
      });
    });
    group('affiliated keyword', () {
      test('with trailing paragraph', () {
        final result = parser.parse('''#+blah
foo''');
        expect(result.value, [
          ['', '#+blah', '\n'],
          [
            '',
            ['foo']
          ]
        ]);
      });
      test('indented', () {
        final result = parser.parse('''   #+blah
foo''');
        expect(result.value, [
          ['   ', '#+blah', '\n'],
          [
            '',
            ['foo']
          ]
        ]);
      });
      test('sandwiched', () {
        // TODO(aaron): Figure out why this fails without the leading 'a'
        final result = parser.parse('''a
#+blah
foo''');
        expect(result.value, [
          [
            '',
            ['a\n']
          ],
          ['', '#+blah', '\n'],
          [
            '',
            ['foo']
          ]
        ]);
      });
    });
    test('list', () {
      final result = parser.parse('''- foo


  bar''');
      expect(result.value, [
        [
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
          '\n'
        ],
        [
          '  ',
          ['bar']
        ]
      ]);
    });
    test('drawer', () {
      final result = parser.parse(''':foo:
:bar: baz
:end:
#+bazinga: bozo''');
      expect(result.value, [
        [
          '',
          [
            [':', 'foo', ':', '\n'],
            [
              [
                '',
                [':', 'bar', ':'],
                ' baz',
                '\n'
              ]
            ],
            ['', ':end:']
          ],
          '\n'
        ],
        ['', '#+bazinga:', ' bozo']
      ]);
    });
    test('block', () {
      final result = parser.parse('''- foo
  #+begin_example
    bar


  #+end_example
  baz
''');
      expect(
        result.value,
        [
          [
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
                      '  ',
                      [
                        ['#+begin_example', '\n'],
                        '    bar\n\n\n',
                        ['  ', '#+end_example']
                      ],
                      '\n'
                    ],
                    [
                      '  ',
                      ['baz\n']
                    ]
                  ]
                ]
              ]
            ],
            ''
          ]
        ],
        // This parse result is incompatible with the requirement that 3
        // linebreaks ends a list item, given the current implementation of
        // IndentedRegionParser
        //
        // TODO(aaron): Fix block parsing inside list item
        skip: true,
      );
    });
    group('arbitrary block', () {
      test('rich text content', () {
        final result = parser.parse('''#+begin_fofo
   bar ~baz~
#+end_fofo''');
        expect(result.value, [
          [
            '',
            [
              ['#+begin_', 'fofo', '\n'],
              [
                '   bar ',
                ['~', 'baz', '~'],
                '\n'
              ],
              ['', '#+end_fofo']
            ],
            ''
          ]
        ]);
      });
      test('https://github.com/amake/orgro/issues/79', () {
        final result = parser.parse('''#+BEGIN_RESULTS
Text
#+END_RESULTS''');
        expect(result.value, [
          [
            '',
            [
              ['#+BEGIN_', 'RESULTS', '\n'],
              ['Text\n'],
              ['', '#+END_RESULTS']
            ],
            ''
          ]
        ]);
      });
      test('mismatched capitalization', () {
        final result = parser.parse('''#+Begin_description
Text
#+end_DESCRIPTION''');
        expect(result.value, [
          [
            '',
            [
              ['#+Begin_', 'description', '\n'],
              ['Text\n'],
              ['', '#+end_DESCRIPTION']
            ],
            ''
          ]
        ]);
      });
    });
    group('LaTeX block', () {
      test('simple', () {
        final result = parser.parse(r'''\begin{equation}
\nabla \cdot \mathbf{B} = 0
\end{equation}
''');
        expect(result.value, [
          [
            '',
            [
              [r'\begin{', 'equation', '}'],
              '\n\\nabla \\cdot \\mathbf{B} = 0\n',
              r'\end{equation}'
            ],
            '\n'
          ]
        ]);
      });
      test('nested', () {
        final result = parser.parse(r'''\begin{equation}
\begin{cases}
   a &\text{if } b \\
   c &\text{if } d
\end{cases} + 1
\end{equation}
''');
        expect(result.value, [
          [
            '',
            [
              [r'\begin{', 'equation', '}'],
              '\n\\begin{cases}\n   a &\\text{if } b \\\\\n   c &\\text{if } d\n\\end{cases} + 1\n',
              r'\end{equation}'
            ],
            '\n'
          ]
        ]);
      });
    });
    group('inline LaTeX', () {
      test(r'single-$ delimiter', () {
        final result = parser.parse(r'foo $bar$ baz');
        expect(result.value, [
          [
            '',
            [
              'foo ',
              [r'$', 'bar', r'$'],
              ' baz'
            ]
          ]
        ]);
      });
      test(r'multiple single-$ delimiter', () {
        final result = parser.parse(r'from $i$ to $j$');
        expect(result.value, [
          [
            '',
            [
              'from ',
              [r'$', 'i', r'$'],
              ' to ',
              [r'$', 'j', r'$']
            ]
          ]
        ]);
      });
      test(r'double-$ delimiter', () {
        final result = parser.parse(r'foo $$ a^2 + b^2 + c^2 $$ baz');
        expect(result.value, [
          [
            '',
            [
              'foo ',
              [r'$$', ' a^2 + b^2 + c^2 ', r'$$'],
              ' baz'
            ]
          ]
        ]);
      });
      test('paren delimiter', () {
        final result = parser.parse(r'foo \(1/0\) baz');
        expect(result.value, [
          [
            '',
            [
              'foo ',
              [r'\(', '1/0', r'\)'],
              ' baz'
            ]
          ]
        ]);
      });
      test('bracket delimiter', () {
        final result = parser.parse(r'foo \[\infty\] baz');
        expect(result.value, [
          [
            '',
            [
              'foo ',
              [r'\[', r'\infty', r'\]'],
              ' baz'
            ]
          ]
        ]);
      });
    });
    group('entity', () {
      test('simple', () {
        final result = parser.parse(r'I think \there4 I am');
        expect(result.value, [
          [
            '',
            [
              'I think ',
              [r'\', 'there4', ''],
              ' I am'
            ]
          ]
        ]);
      });
      test('before line break', () {
        final result = parser.parse(r'''I think \there4
I am''');
        expect(result.value, [
          [
            '',
            [
              'I think ',
              [r'\', 'there4', ''],
              '\nI am'
            ]
          ]
        ]);
      });
      test('at end of input', () {
        final result = parser.parse(r'I think \there4');
        expect(result.value, [
          [
            '',
            [
              'I think ',
              [r'\', 'there4', ''],
            ]
          ]
        ]);
      });
      test('with terminator at end of input', () {
        final result = parser.parse(r'I think \there4{}');
        expect(result.value, [
          [
            '',
            [
              'I think ',
              [r'\', 'there4', '{}'],
            ]
          ]
        ]);
      });
      test('with terminator abutting text', () {
        final result = parser.parse(r'I think \there4{}I am');
        expect(result.value, [
          [
            '',
            [
              'I think ',
              [r'\', 'there4', '{}'],
              'I am'
            ]
          ]
        ]);
      });
    });
    test('local variables', () {
      final result = parser.parse('''foo
  # Local Variables:
  # my-foo: bar
  # End:

bar
''');
      expect(
        result.value,
        [
          [
            '',
            ['foo\n']
          ],
          [
            '  # Local Variables:\n',
            [
              ['  # ', 'my-foo: bar', '\n']
            ],
            '  # End:\n'
          ],
          [
            '',
            ['\nbar\n']
          ]
        ],
      );
    });
    test('detect common problems', () {
      expect(
        linter(parser, excludedTypes: {LinterType.info}),
        isEmpty,
        // TODO(aaron): There are two warnings about repeated choice, but
        // there's no hint as to where in the grammar they are.
        skip: true,
      );
    });
  });
}
