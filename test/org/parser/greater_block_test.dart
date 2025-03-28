import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.greaterBlock()).end();
  test('greater block', () {
    final result = parser.parse('''#+begin_center
  foo ~bar~
  bizbaz
#+end_center
''');
    final block = result.value as OrgBlock;
    expect(block.header, '#+begin_center\n');
    final body = block.body as OrgContent;
    final child1 = body.children[0] as OrgParagraph;
    expect(child1.indent, '  ');
    final gchild1 = child1.body.children.first as OrgPlainText;
    expect(gchild1.content, 'foo ');
    final gchild2 = child1.body.children[1] as OrgMarkup;
    final ggchild1Body = gchild2.content.children.first as OrgPlainText;
    expect(ggchild1Body.content, 'bar');
    expect(block.footer, '#+end_center');
    expect(block.trailing, '\n');
    expect(block.type, 'center');
  });
}
