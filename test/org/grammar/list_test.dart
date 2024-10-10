// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('list', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.list()).end();
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
}
