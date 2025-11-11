import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final grammar = OrgContentGrammarDefinition();
  final parser = grammar.buildFrom(grammar.table()).end();
  test('table', () {
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
            [' ', 'foo', ' |'],
            [' ', 'bar', ' |'],
            [' ', 'baz', ' |']
          ],
          '\n'
        ],
        ['  ', '|-----+-----+-----|', '\n'],
        [
          '  ',
          '|',
          [
            ['   ', '1', ' |'],
            ['   ', '2', ' |'],
            ['   ', '3', ' |']
          ],
          '\n'
        ]
      ],
      ''
    ]);
  });
  test('table containing plus', () {
    // https://github.com/amake/orgro/issues/175
    final result = parser.parse('''  |-------+------|
| +Text | Text |
|-------+------|
|     5 |  -10 |
|-------+------|
''');
    expect(result.value, [
      [
        ['  ', '|-------+------|', '\n'],
        [
          '',
          '|',
          [
            [' ', '+Text', ' |'],
            [' ', 'Text', ' |']
          ],
          '\n'
        ],
        ['', '|-------+------|', '\n'],
        [
          '',
          '|',
          [
            ['     ', '5', ' |'],
            ['  ', '-10', ' |']
          ],
          '\n'
        ],
        ['', '|-------+------|', '\n']
      ],
      ''
    ]);
  });
  test('minimal table', () {
    final result = parser.parse('+-+');
    expect(result.value, [
      [
        ['', '+-+', '']
      ],
      ''
    ]);
  });
  test('minimal table 2', () {
    // This doesn't look valid but `table-recognize` accepts it.
    final result = parser.parse('+--');
    expect(result.value, [
      [
        ['', '+--', '']
      ],
      ''
    ]);
  });
  test('invalid', () {
    // https://github.com/amake/orgro/issues/177
    final result = parser.parse('''+- Some text here+''');
    expect(result, isA<Failure>());
  });
}
