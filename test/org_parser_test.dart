import 'package:org_parser/org_parser.dart';
import 'package:test/test.dart';

void main() {
  final grammar = OrgGrammar();
  test('parse a header', () {
    final result = grammar.parse('* Title');
    expect(result.value, [
      [
        [
          ['*'],
          null,
          null,
          ['T', 'i', 't', 'l', 'e'],
          null
        ],
        null
      ]
    ]);
  });
  test('parse a todo header', () {
    final result = grammar.parse('* TODO Title');
    expect(result.value, [
      [
        [
          ['*'],
          'TODO',
          null,
          ['T', 'i', 't', 'l', 'e'],
          null
        ],
        null
      ]
    ]);
  });
  test('parse a section', () {
    final result = grammar.parse('''* Title
  Content1
  Content2''');
    expect(result.value, [
      [
        [
          ['*'],
          null,
          null,
          ['T', 'i', 't', 'l', 'e'],
          null
        ],
        [
          'C',
          'o',
          'n',
          't',
          'e',
          'n',
          't',
          '1',
          '\n'
              '',
          ' ',
          ' ',
          'C',
          'o',
          'n',
          't',
          'e',
          'n',
          't',
          '2'
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
}
