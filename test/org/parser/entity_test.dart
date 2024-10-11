import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('entity', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.entity()).end();
    test('simple', () {
      final result = parser.parse(r'\frac12');
      final entity = result.value as OrgEntity;
      expect(entity.leading, r'\');
      expect(entity.name, r'frac12');
      expect(entity.trailing, '');
    });
    test('with terminator', () {
      final result = parser.parse(r'\foobar{}');
      final entity = result.value as OrgEntity;
      expect(entity.leading, r'\');
      expect(entity.name, r'foobar');
      expect(entity.trailing, '{}');
    });
  });
}
