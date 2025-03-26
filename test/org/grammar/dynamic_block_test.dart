import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('dynamic block', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.dynamicBlock()).end();
    test('normal', () {
      final result =
          parser.parse('''#+BEGIN: myblock :parameter1 value1 :parameter2 value2
  foobar
#+END:
''');
      expect(result.value, [
        '',
        [
          [
            '#+BEGIN:',
            [' ', 'myblock'],
            ' :parameter1 value1 :parameter2 value2\n'
          ],
          '  foobar\n',
          ['', '#+END:']
        ],
        '\n'
      ]);
    });
    test('lower case', () {
      final result =
          parser.parse('''#+begin: myblock :parameter1 value1 :parameter2 value2
  foobar
#+end:
''');
      expect(result.value, [
        '',
        [
          [
            '#+begin:',
            [' ', 'myblock'],
            ' :parameter1 value1 :parameter2 value2\n'
          ],
          '  foobar\n',
          ['', '#+end:']
        ],
        '\n'
      ]);
    });
    test('invalid', () {
      final result = parser.parse('''#+BEGIN:
  foobar
#+END:
''');
      expect(result, isA<Failure>());
    });
  });
}
