import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('horizontal rule', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.horizontalRule()).end();
    test('minimal', () {
      final markup = '-----';
      final result = parser.parse(markup);
      final rule = result.value as OrgHorizontalRule;
      expect(rule.toMarkup(), markup);
      expect(rule.contains('-----'), isTrue);
      expect(rule.contains('あ'), isFalse);
    });
    test('trailing', () {
      final markup = '''-----${' '}
''';
      final result = parser.parse(markup);
      final rule = result.value as OrgHorizontalRule;
      expect(rule.toMarkup(), markup);
      expect(rule.contains(' '), isTrue);
      expect(rule.contains('あ'), isFalse);
    });
  });
}
