import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('link target', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.linkTarget()).end();
    test('single character', () {
      final result = parser.parse('<<!>>');
      final target = result.value as OrgLinkTarget;
      expect(target.leading, '<<');
      expect(target.body, '!');
      expect(target.trailing, '>>');
    });
    test('multiple words', () {
      final result = parser.parse('<<foo bar>>');
      final target = result.value as OrgLinkTarget;
      expect(target.leading, '<<');
      expect(target.body, 'foo bar');
      expect(target.trailing, '>>');
    });
  });
}
