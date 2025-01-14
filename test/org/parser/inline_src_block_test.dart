import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('inline src', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.inlineSourceBlock()).end();
    test('no args', () {
      final result = parser.parse('''src_sh{echo "foo"}''');
      final block = result.value as OrgInlineSrcBlock;
      expect(block.leading, 'src_');
      expect(block.language, 'sh');
      expect(block.arguments, isNull);
      expect(block.body, '{echo "foo"}');
    });
    test('with args', () {
      final result = parser.parse('''src_ruby[:exports code]{println "foo"}''');
      final block = result.value as OrgInlineSrcBlock;
      expect(block.leading, 'src_');
      expect(block.language, 'ruby');
      expect(block.arguments, '[:exports code]');
      expect(block.body, '{println "foo"}');
    });
  });
}
