import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('dynamic block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.dynamicBlock()).end();
    test('normal', () {
      final result =
          parser.parse('''#+BEGIN: myblock :parameter1 value1 :parameter2 value2
  foobar
#+END:
''');
      final block = result.value as OrgDynamicBlock;
      expect(block.header,
          '#+BEGIN: myblock :parameter1 value1 :parameter2 value2\n');
      expect(block.body.children[0].toMarkup(), '  foobar\n');
      expect(block.footer, '#+END:');
      expect(block.trailing, '\n');
    });
  });
}
