import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('subscript', () {
    final definition = OrgContentParserDefinition();
    final parser =
        seq2(letter(), definition.buildFrom(definition.subscript())).end();
    test('H2O', () {
      final result = parser.parse(r'H_2O');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_');
      final body = sup.body.children.single as OrgPlainText;
      expect(body.content, '2O');
      expect(sup.trailing, '');
    });
    test('with entity', () {
      final result = parser.parse(r'a_\alpha');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_');
      final body = sup.body.children.single as OrgEntity;
      expect(body.name, 'alpha');
      expect(sup.trailing, '');
    });
    test('with text and entity', () {
      final result = parser.parse(r'a_{1 + \alpha}');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_{');
      final body1 = sup.body.children[0] as OrgPlainText;
      expect(body1.content, '1 + ');
      final body2 = sup.body.children[1] as OrgEntity;
      expect(body2.name, 'alpha');
      expect(sup.trailing, '}');
    });
    test('nested bracketed expression', () {
      final result = parser.parse('a_{a1 {b2}}');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_{');
      final body = sup.body.children.single as OrgPlainText;
      expect(body.content, 'a1 {b2}');
      expect(sup.trailing, '}');
    });
    test('nested sexp', () {
      final result = parser.parse('a_(a1 (b2))');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_');
      final body = sup.body.children.single as OrgPlainText;
      expect(body.content, '(a1 (b2))');
      expect(sup.trailing, '');
    });
    test('nested subscript', () {
      final result = parser.parse('a_{a1_{b2}}');
      final (_, OrgSubscript sup) = result.value;
      final nested =
          sup.find<OrgSubscript>((node) => node.toMarkup() == '_{b2}');
      expect(nested, isNotNull);
    });
  });
}
