// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

void main() {
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
          ],
          '\n\n',
        ],
        [
          '  ',
          [
            ['#+begin_quote', '\n'],
            '    blah\n',
            ['  ', '#+end_quote']
          ],
          '\n'
        ],
        [
          '',
          ['bazinga'],
          ''
        ]
      ]);
    });
    group('markup', () {
      test('markup edge case', () {
        // https://github.com/amake/orgro/issues/177
        final result = parser.parse('''+- Some text here+
- Some text here''');
        expect(result.value, [
          [
            '',
            [
              ['+', '- Some text here', '+'],
              '\n'
            ],
            ''
          ],
          [
            [
              [
                '',
                '-',
                [
                  ' ',
                  null,
                  null,
                  ['Some text here']
                ]
              ]
            ],
            ''
          ]
        ]);
      });
    });
    group('link', () {
      test('bare HTTP URL', () {
        final result = parser.parse('a http://example.com b');
        expect(result.value, [
          [
            '',
            ['a ', 'http://example.com', ' b'],
            '',
          ]
        ]);
      });
      test('bare HTTPS URL', () {
        final result = parser.parse('a https://example.com b');
        expect(result.value, [
          [
            '',
            ['a ', 'https://example.com', ' b'],
            '',
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
            ],
            ''
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
            ],
            ''
          ]
        ]);
      });
    });
    group('affiliated keyword', () {
      test('with trailing paragraph', () {
        final result = parser.parse('''#+blah:
foo''');
        expect(result.value, [
          [
            '',
            ['#+blah:', ''],
            '\n'
          ],
          [
            '',
            ['foo'],
            ''
          ]
        ]);
      });
      test('indented', () {
        final result = parser.parse('''   #+blah:
foo''');
        expect(result.value, [
          [
            '   ',
            ['#+blah:', ''],
            '\n'
          ],
          [
            '',
            ['foo'],
            ''
          ]
        ]);
      });
      test('sandwiched', () {
        // TODO(aaron): Figure out why this fails without the leading 'a'
        final result = parser.parse('''a
#+blah:
foo''');
        expect(result.value, [
          [
            '',
            ['a\n'],
            ''
          ],
          [
            '',
            ['#+blah:', ''],
            '\n'
          ],
          [
            '',
            ['foo'],
            ''
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
              '-',
              [
                ' ',
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
          ['bar'],
          ''
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
        [
          '',
          ['#+bazinga:', ' bozo'],
          ''
        ]
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
                '-',
                [
                  ' ',
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
                      ['baz'],
                      '\n'
                    ]
                  ]
                ]
              ]
            ],
            ''
          ]
        ],
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
              'fofo',
              ['#+begin_', 'fofo', '\n'],
              [
                [
                  '   ',
                  [
                    'bar ',
                    ['~', 'baz', '~'],
                  ],
                  '\n'
                ]
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
              'RESULTS',
              ['#+BEGIN_', 'RESULTS', '\n'],
              [
                [
                  '',
                  ['Text'],
                  '\n'
                ]
              ],
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
              'description',
              ['#+Begin_', 'description', '\n'],
              [
                [
                  '',
                  ['Text'],
                  '\n'
                ]
              ],
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
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
            ],
            ''
          ]
        ]);
      });
    });
    group('superscript', () {
      test('simple', () {
        final result = parser.parse(r'I think there^4 I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '4'],
              ' I am'
            ],
            ''
          ]
        ]);
      });
      test('trailing comma', () {
        final result = parser.parse(r'I drink H_2O, OK?');
        expect(result.value, [
          [
            '',
            [
              'I drink H',
              ['_', '2O'],
              ', OK?'
            ],
            ''
          ]
        ]);
        // This fails because the "reverseId" formulation fails when it sees the
        // trailing comma (which is an "inner" character), and we can't
        // backtrack. Org Mode handles this correctly because it uses regex and
        // can backtrack. Tweaking reverseId to handle this case breaks the
        // "edge case" subscript grammar test.
      }, skip: 'TODO(aaron): Fix subscript edge case');
      test('before line break', () {
        final result = parser.parse(r'''I think there^4
I am''');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '4'],
              '\nI am'
            ],
            ''
          ]
        ]);
      });
      test('at end of input', () {
        final result = parser.parse(r'I think there^4');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '4'],
            ],
            ''
          ]
        ]);
      });
      test('with delimiters', () {
        final result = parser.parse(r'I think there^{4}');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '{4}'],
            ],
            ''
          ]
        ]);
      });
      test('with delimiters abutting text', () {
        final result = parser.parse(r'I think there^{4}I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '{4}'],
              'I am'
            ],
            ''
          ]
        ]);
      });
      test('with sexp', () {
        final result = parser.parse(r'I think there^(4 + 4)I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '(4 + 4)'],
              'I am'
            ],
            ''
          ]
        ]);
      });
      test('with multiple undelimited chars', () {
        final result = parser.parse(r'I think there^four I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', 'four'],
              ' I am'
            ],
            ''
          ]
        ]);
      });
      test('with asterisk', () {
        final result = parser.parse(r'I think there^*I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '*'],
              'I am'
            ],
            ''
          ]
        ]);
      });
      test('with trailing subscript', () {
        final result = parser.parse(r'I think there^4_I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['^', '4'],
              ['_', 'I'],
              ' am'
            ],
            ''
          ]
        ]);
      });
      test('with leading subscript', () {
        final result = parser.parse(r'I think there_4^I am');
        expect(result.value, [
          [
            '',
            [
              'I think there',
              ['_', '4'],
              ['^', 'I'],
              ' am'
            ],
            ''
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
            ['foo\n'],
            ''
          ],
          [
            [
              '  # Local Variables:\n',
              [
                ['  # ', 'my-foo: bar', '\n']
              ],
              '  # End:'
            ],
            '\n\n'
          ],
          [
            '',
            ['bar'],
            '\n'
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

/*
Make Emacs ignore the local variables declarations above:

*/
