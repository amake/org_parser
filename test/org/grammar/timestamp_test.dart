// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('timestamps', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.timestamp()).end();
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
    test('with repeater (min/max)', () {
      final result = parser.parse('''<2020-03-12 Wed 8:34 +1w/2w>''');
      expect(result.value, [
        '<',
        ['2020', '-', '03', '-', '12', 'Wed'],
        ['8', ':', '34'],
        [
          ['+', '1', 'w', '/', '2', 'w'],
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
    test('without day of week', () {
      final result = parser.parse(
          '''[2020-03-11 18:34 .+1w --12d]--[2020-03-12 18:34 .+1w --12d]''');
      expect(result.value, [
        [
          '[',
          ['2020', '-', '03', '-', '11', null],
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
          ['2020', '-', '03', '-', '12', null],
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
      final result = parser.parse('''<%%(what (the (f))) foo>''');
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
        ' foo',
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
    test('min/max with hour', () {
      final result = parser.parse('''[2020-03-11 Wed 18:34:56 .+1h/2h]''');
      expect(result, isA<Failure>(), reason: 'Hours not supported for min/max');
    });
    test('min/max delay', () {
      final result = parser.parse('''[2020-03-11 Wed 18:34:56 -1d/2d]''');
      expect(result, isA<Failure>(), reason: 'Min/max not supported on delay');
    });
  });
}
