import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.arbitraryGreaterBlock()).end();
  test('arbitrary block', () {
    final markup = '''#+begin_blah
  foo ~bar~
  bizbaz
#+end_blah
''';
    final result = parser.parse(markup);
    final block = result.value as OrgBlock;
    expect(block.contains('bizbaz'), isTrue);
    expect(block.toMarkup(), markup);
  });
}
