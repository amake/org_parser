import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('subscript', () {
    final definition = OrgContentParserDefinition();
    final parser =
        seq2(letter(), definition.buildFrom(definition.subscript())).end();
    test('with entity', () {
      final result = parser.parse(r'a_\alpha');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.contains('alpha'), isTrue);
      expect(sup.contains(r'\alpha'), isFalse);
      expect(sup.toMarkup(), r'_\alpha');
      expect(sup.toPlainText(), r'_\alpha');
    });
    test('nested bracketed expression', () {
      final result = parser.parse('a_{a1 {b2}}');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.contains('b2'), isTrue);
      expect(sup.contains('あ'), isFalse);
      expect(sup.toMarkup(), '_{a1 {b2}}');
      expect(sup.toPlainText(), '_{a1 {b2}}');
    });
  });
}
