// ignore_for_file: inference_failure_on_collection_literal

import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('document grammar', () {
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
}
