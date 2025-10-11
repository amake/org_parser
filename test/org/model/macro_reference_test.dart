import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('macro reference', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.macroReference()).end();
    test('with args', () {
      final markup = '{{{name(arg1, arg2)}}}';
      var result = parser.parse(markup);
      var ref = result.value as OrgMacroReference;
      expect(ref.contains('name'), isTrue);
      expect(ref.contains('あ'), isFalse);
      expect(ref.toMarkup(), markup);
      expect(ref.toPlainText(), markup);
    });
    test('simple', () {
      final markup = '{{{foobar}}}';
      final result = parser.parse(markup);
      final ref = result.value as OrgMacroReference;
      expect(ref.contains('foobar'), isTrue);
      expect(ref.contains('あ'), isFalse);
      expect(ref.toMarkup(), markup);
      expect(ref.toPlainText(), markup);
    });
  });
}
