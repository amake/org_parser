import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link target', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.linkTarget()).end();
    test('single character', () {
      final markup = '<<!>>';
      final target = parser.parse(markup).value as OrgLinkTarget;
      expect(target.contains('!'), isTrue);
      expect(target.contains('あ'), isFalse);
      expect(target.toMarkup(), markup);
    });
    test('multiple workds', () {
      final markup = '<<foo bar>>';
      final target = parser.parse(markup).value as OrgLinkTarget;
      expect(target.contains('foo'), isTrue);
      expect(target.contains('あ'), isFalse);
      expect(target.toMarkup(), markup);
    });
  });
}
