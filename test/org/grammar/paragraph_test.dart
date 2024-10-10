import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('paragraph', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.paragraph()).end();
    test('with line break', () {
      final result = parser.parse('''foo bar
biz baz''');
      expect(result.value, [
        '',
        ['foo bar\nbiz baz']
      ]);
    });
    test('with inline objects', () {
      final result =
          parser.parse('''go to [[http://example.com][example]] for *fun*,
maybe''');
      expect(result.value, [
        '',
        [
          'go to ',
          [
            '[',
            ['[', 'http://example.com', ']'],
            ['[', 'example', ']'],
            ']'
          ],
          ' for ',
          ['*', 'fun', '*'],
          ',\nmaybe'
        ]
      ]);
    });
  });
}
