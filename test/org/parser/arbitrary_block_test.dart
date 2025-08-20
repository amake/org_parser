import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('arbitrary block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.arbitraryGreaterBlock()).end();
    test('example block', () {
      final result = parser.parse('''#+begin_example
  echo 'foo'
  rm bar
#+end_example
''');
      final block = result.value as OrgBlock;
      final body = block.body as OrgContent;
      expect(block.header, '#+begin_example\n');
      expect(body.toMarkup(), '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_example');
      expect(block.trailing, '\n');
      expect(block.type, 'example');
    });
    test('almost example block', () {
      final result = parser.parse('''#+begin_examplek
  echo 'foo'
  rm bar
#+end_examplek
''');
      final block = result.value as OrgBlock;
      final body = block.body as OrgContent;
      expect(block.header, '#+begin_examplek\n');
      expect(body.toMarkup(), '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_examplek');
      expect(block.trailing, '\n');
      expect(block.type, 'examplek');
    });
    group('source block', () {
      test('simple', () {
        final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
        final block = result.value as OrgBlock;
        final body = block.body as OrgContent;
        expect(block.header, '#+begin_src sh\n');
        expect(body.toMarkup(), '  echo \'foo\'\n  rm bar\n');
        expect(block.footer, '#+end_src');
        expect(block.trailing, '\n');
        expect(block.type, 'src');
      });
      test('empty', () {
        final result = parser.parse('''#+begin_src
#+end_src''');
        final block = result.value as OrgBlock;
        final body = block.body as OrgContent;
        expect(block.header, '#+begin_src\n');
        expect(body.toMarkup(), '');
        expect(block.footer, '#+end_src');
        expect(block.trailing, '');
        expect(block.type, 'src');
      });
    });
    test('almost src block', () {
      final result = parser.parse('''#+begin_srcc sh
  echo 'foo'
  rm bar
#+end_srcc
''');
        final block = result.value as OrgBlock;
        final body = block.body as OrgContent;
        expect(block.header, '#+begin_srcc sh\n');
        expect(body.toMarkup(), '  echo \'foo\'\n  rm bar\n');
        expect(block.footer, '#+end_srcc');
        expect(block.trailing, '\n');
        expect(block.type, 'srcc');
    });
  });
}
