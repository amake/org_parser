import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('local variables', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.localVariables()).end();
    test('simple', () {
      final result = parser.parse('''# Local Variables:
# foo: bar
# End: ''');
      final variables = result.value as OrgLocalVariables;
      expect(variables.start, '# Local Variables:\n');
      expect(variables.trailing, '# End: ');
      expect(variables.entries.length, 1);
      expect(
        variables.entries[0],
        (prefix: '# ', content: 'foo: bar', suffix: '\n'),
      );
    });
    test('with indent and suffix', () {
      final result = parser.parse(''' /* Local Variables: */
 /* foo: bar */
 /* baz: bazinga */
 /* End: */''');
      final variables = result.value as OrgLocalVariables;
      expect(variables.start, ' /* Local Variables: */\n');
      expect(variables.trailing, ' /* End: */');
      expect(variables.entries.length, 2);
      expect(
        variables.entries[0],
        (prefix: ' /* ', content: 'foo: bar ', suffix: '*/\n'),
      );
    });
  });
}
