import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('inline src', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.inlineSourceBlock()).end();
    test('no args', () {
      final markup = '''src_sh{echo "foo"}''';
      final result = parser.parse(markup);
      final block = result.value as OrgInlineSrcBlock;
      expect(block.contains('echo "foo"'), isTrue);
      expect(block.contains('sh'), isTrue);
      expect(block.contains('あ'), isFalse);
      expect(block.toMarkup(), markup);
    });
    test('with args', () {
      final markup = '''src_ruby[:exports code]{println "foo"}''';
      final result = parser.parse(markup);
      final block = result.value as OrgInlineSrcBlock;
      expect(block.contains('println "foo"'), isTrue);
      expect(block.contains('ruby'), isTrue);
      expect(block.contains(':exports'), isTrue);
      expect(block.contains('あ'), isFalse);
      expect(block.toMarkup(), markup);
    });
  });
}
