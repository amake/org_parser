import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('subscript', () {
    final definition = OrgContentParserDefinition();
    final parser =
        seq2(letter(), definition.buildFrom(definition.subscript())).end();
    test('nested bracketed expression', () {
      final result = parser.parse('a_{a1 {b2}}');
      final (_, OrgSubscript sup) = result.value;
      expect(sup.leading, '_');
      expect(sup.body, '{a1 {b2}}');
    });
  });
}
