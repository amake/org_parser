import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('local variables', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.localVariables()).end();
    test('simple', () {
      final markup = '''# Local Variables:
# foo: bar
# End: ''';
      final result = parser.parse(markup);
      final lvars = result.value as OrgLocalVariables;
      expect(lvars.contains('foo'), isTrue);
      expect(lvars.contains('あ'), isFalse);
      expect(lvars.toMarkup(), markup);
    });
    test('with suffix', () {
      final markup = '''# Local Variables: #
# foo: bar #
# End: #''';
      final result = parser.parse(markup);
      final lvars = result.value as OrgLocalVariables;
      expect(lvars.contains('foo'), isTrue);
      expect(lvars.contains('あ'), isFalse);
      expect(lvars.toMarkup(), markup);
    });
  });
}
