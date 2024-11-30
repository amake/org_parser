import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.block()).end();
    test('block', () {
      final markup = '''#+begin_example
  echo 'foo'
  rm bar
#+end_example
''';
      final result = parser.parse(markup);
      final block = result.value as OrgBlock;
      expect(block.contains("echo 'foo'"), isTrue);
      expect(block.contains('あ'), isFalse);
      expect(block.toMarkup(), markup);
    });
    group('source block', () {
      test('simple', () {
        final markup = '''#+begin_src sh
  echo 'foo'
  rm bar
#+end_src
''';
        var result = parser.parse(markup);
        var block = result.value as OrgSrcBlock;
        expect(block.contains("echo 'foo'"), isTrue);
        expect(block.contains('あ'), isFalse);
        expect(block.toMarkup(), markup);
      });
      test('empty', () {
        final markup = '''#+begin_src
#+end_src''';
        final result = parser.parse(markup);
        final block = result.value as OrgSrcBlock;
        expect(block.contains('あ'), isFalse);
        expect(block.toMarkup(), markup);
      });
    });
  });
}
