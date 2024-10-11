import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('fixed-width area', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.fixedWidthArea()).end();
    test('multiline', () {
      final result = parser.parse(''': foo
: bar
''');
      final area = result.value as OrgFixedWidthArea;
      expect(area.content, ''': foo
: bar
''');
    });
    test('empty', () {
      final result = parser.parse(': ');
      final area = result.value as OrgFixedWidthArea;
      expect(area.content, ': ');
    });
  });
}
