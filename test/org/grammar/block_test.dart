import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('block', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.block()).end();
    test('lower case', () {
      final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src''');
      expect(result.value, [
        '',
        [
          [
            '#+begin_src',
            [' ', 'sh'],
            '\n'
          ],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+end_src']
        ],
        ''
      ]);
    });
    test('mismatched case', () {
      final result = parser.parse('''#+BEGIN_SRC sh
  echo 'foo'
  rm bar
#+EnD_sRC
''');
      expect(result.value, [
        '',
        [
          [
            '#+BEGIN_SRC',
            [' ', 'sh'],
            '\n'
          ],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+EnD_sRC']
        ],
        '\n'
      ]);
    });
    test('no language', () {
      final result = parser.parse('''#+begin_src
  echo 'foo'
  rm bar
#+end_src
''');
      expect(result.value, [
        '',
        [
          ['#+begin_src', null, '\n'],
          '  echo \'foo\'\n  rm bar\n',
          ['', '#+end_src']
        ],
        '\n'
      ]);
    });
  });
}
