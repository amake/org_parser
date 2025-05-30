// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('drawer', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.drawer()).end();
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
    test('non-ASCII', () {
      final result = parser.parse(''':あ:
:end:''');
      expect(result.value, [
        '',
        [
          [':', 'あ', ':', '\n'],
          [],
          ['', ':end:']
        ],
        ''
      ]);
    });
    test('underline', () {
      final result = parser.parse(''':DRAWER_ONE:
foo
:END:''');
      expect(result.value, [
        '',
        [
          [':', 'DRAWER_ONE', ':', '\n'],
          ['foo\n'],
          ['', ':END:']
        ],
        ''
      ]);
    });
    test('hyphen', () {
      final result = parser.parse(''':DRAWER-ONE:
foo
:END:''');
      expect(result.value, [
        '',
        [
          [':', 'DRAWER-ONE', ':', '\n'],
          ['foo\n'],
          ['', ':END:']
        ],
        ''
      ]);
    });
    test('period', () {
      final result = parser.parse(''':DRAWER.ONE:
foo
:END:''');
      expect(result, isA<Failure>());
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
              'CLOCK:',
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
              ]
            ],
            ' =>  0:49\n'
          ],
          ['', ':END:']
        ],
        '\n'
      ]);
    });
    test('short property value', () {
      final result = parser.parse(''':PROPERTIES:
:foo: bar
:baz: t
:END:''');
      expect(result.value, [
        '',
        [
          [':', 'PROPERTIES', ':', '\n'],
          [
            [
              '',
              [':', 'foo', ':'],
              ' bar',
              '\n'
            ],
            [
              '',
              [':', 'baz', ':'],
              ' t',
              '\n'
            ]
          ],
          ['', ':END:']
        ],
        ''
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
    test('https://github.com/amake/org_parser/issues/3', () {
      final result = parser.parse(''':PROPERTIES:
  :expectedNodes: 6
  :archivedNodes:2
  :END:
  you can define also the drawer using the following directive....
#+DRAWERS: DRAWER_ONE DRAWER_TWO Drawer1 Drawer2
:DRAWER_ONE:
I am drawer one, with one line
:END:
''');
      expect(result, isA<Failure>());
    });
  });
}
