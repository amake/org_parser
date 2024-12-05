import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('superscript', () {
    final definition = OrgContentParserDefinition();
    final parser =
        seq2(letter(), definition.buildFrom(definition.superscript())).end();
    test('with entity', () {
      final result = parser.parse(r'a^\alpha');
      final (_, OrgSuperscript sup) = result.value;
      expect(sup.leading, '^');
      final body = sup.body.children.single as OrgEntity;
      expect(body.name, 'alpha');
      expect(sup.trailing, '');
    });
    test('with text and entity', () {
      final result = parser.parse(r'a^{1 + \alpha}');
      final (_, OrgSuperscript sup) = result.value;
      expect(sup.leading, '^{');
      final body1 = sup.body.children[0] as OrgPlainText;
      expect(body1.content, '1 + ');
      final body2 = sup.body.children[1] as OrgEntity;
      expect(body2.name, 'alpha');
      expect(sup.trailing, '}');
    });
    test('nested bracketed expression', () {
      final result = parser.parse('a^{a1 {b2}}');
      final (_, OrgSuperscript sup) = result.value;
      expect(sup.leading, '^{');
      final body = sup.body.children.single as OrgPlainText;
      expect(body.content, 'a1 {b2}');
      expect(sup.trailing, '}');
    });
    test('nested sexp', () {
      final result = parser.parse('a^(a1 (b2))');
      final (_, OrgSuperscript sup) = result.value;
      expect(sup.leading, '^');
      final body = sup.body.children.single as OrgPlainText;
      expect(body.content, '(a1 (b2))');
      expect(sup.trailing, '');
    });
    test('nested superscript', () {
      final result = parser.parse('a^{a1^{b2}}');
      final (_, OrgSuperscript sup) = result.value;
      final nested =
          sup.find<OrgSuperscript>((node) => node.toMarkup() == '^{b2}');
      expect(nested, isNotNull);
    });
  });
}
