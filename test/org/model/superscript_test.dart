import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('superscript', () {
    final definition = OrgContentParserDefinition();
    final parser =
        seq2(letter(), definition.buildFrom(definition.superscript())).end();
    test('nested bracketed expression', () {
      final result = parser.parse('a^{a1 {b2}}');
      final (_, OrgSuperscript sup) = result.value;
      expect(sup.contains('b2'), isTrue);
      expect(sup.toMarkup(), '^{a1 {b2}}');
    });
  });
}
