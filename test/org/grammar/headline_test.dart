import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import '../../matchers.dart';

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
        'Title foo bar ',
        [
          ':',
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
}
