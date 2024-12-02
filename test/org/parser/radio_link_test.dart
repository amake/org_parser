import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('radio link', () {
    final definition = OrgContentParserDefinition(radioTargets: ['foo', 'bar']);
    final parser = definition.buildFrom(definition.radioLink()).end();
    test('simple', () {
      final result = parser.parse('foo');
      final target = result.value as OrgRadioLink;
      expect(target.content, 'foo');
    });
  });
}
