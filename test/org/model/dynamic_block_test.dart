import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('dynamic block', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.dynamicBlock()).end();
    test('normal', () {
      final markup = '''#+BEGIN: myblock :parameter1 value1 :parameter2 value2
  foobar
#+END:
''';
      final result = parser.parse(markup);
      final block = result.value as OrgDynamicBlock;
      expect(block.contains('myblock'), isTrue);
      expect(block.contains('foobar'), isTrue);
      expect(block.contains('あ'), isFalse);
      expect(block.toMarkup(), markup);
      expect(block.toPlainText(), markup);
    });
  });
}
