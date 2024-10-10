import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  test('table', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.table()).end();
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
}
