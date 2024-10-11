import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.greaterBlock()).end();
  test('greater block', () {
    final markup = '''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''';
    final result = parser.parse(markup);
    final block = result.value as OrgBlock;
    expect(block.contains('bizbaz'), isTrue);
    expect(block.contains('foo ~bar~'), false);
    expect(block.toMarkup(), markup);
  });
}
