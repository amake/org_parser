// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  test('planning line', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.planningLine()).end();
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
}
