import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('horizontal rule', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.horizontalRule()).end();
    test('minimal', () {
      final result = parser.parse('-----');
      final rule = result.value as OrgHorizontalRule;
      expect(rule.indent, '');
      expect(rule.content, '-----');
      expect(rule.trailing, '');
    });
    test('indented', () {
      final result = parser.parse(' -----');
      final rule = result.value as OrgHorizontalRule;
      expect(rule.indent, ' ');
      expect(rule.content, '-----');
      expect(rule.trailing, '');
    });
    test('trailing', () {
      final result = parser.parse('''-----${' '}
''');
      final rule = result.value as OrgHorizontalRule;
      expect(rule.indent, '');
      expect(rule.content, '-----');
      expect(rule.trailing, ' \n');
    });
  });
}
