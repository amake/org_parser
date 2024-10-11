import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.block()).end();
    test('example block', () {
      final result = parser.parse('''#+begin_example
  echo 'foo'
  rm bar
#+end_example
''');
      final block = result.value as OrgBlock;
      final body = block.body as OrgMarkup;
      expect(block.header, '#+begin_example\n');
      expect(body.content, '  echo \'foo\'\n  rm bar\n');
      expect(block.footer, '#+end_example');
      expect(block.trailing, '\n');
    });
    group('source block', () {
      test('simple', () {
        final result = parser.parse('''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''');
        final block = result.value as OrgSrcBlock;
        final body = block.body as OrgPlainText;
        expect(block.language, 'sh');
        expect(block.header, '#+begin_src sh\n');
        expect(body.content, '  echo \'foo\'\n  rm bar\n');
        expect(block.footer, '#+end_src');
        expect(block.trailing, '\n');
      });
      test('empty', () {
        final result = parser.parse('''#+begin_src
#+end_src''');
        final block = result.value as OrgSrcBlock;
        final body = block.body as OrgPlainText;
        expect(block.language, isNull);
        expect(body.content, '');
      });
    });
  });
}
