import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('greater block', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.greaterBlock()).end();
    test('lower case', () {
      final result = parser.parse('''#+begin_quote
  foo *bar*
#+end_quote''');
      expect(result.value, [
        '',
        [
          ['#+begin_quote', '\n'],
          [
            '  foo ',
            ['*', 'bar', '*'],
            '\n'
          ],
          ['', '#+end_quote']
        ],
        ''
      ]);
    });
    test('mismatched case', () {
      final result = parser.parse('''#+BEGIN_QUOTE
  foo /bar/
#+EnD_qUOtE
''');
      expect(result.value, [
        '',
        [
          ['#+BEGIN_QUOTE', '\n'],
          [
            '  foo ',
            ['/', 'bar', '/'],
            '\n'
          ],
          ['', '#+EnD_qUOtE']
        ],
        '\n'
      ]);
    });
  });
}
