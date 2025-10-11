import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('entity', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.entity()).end();
    test('simple', () {
      final markup = r'\frac12';
      final result = parser.parse(markup);
      final entity = result.value as OrgEntity;
      expect(entity.contains('frac12'), isTrue);
      expect(entity.contains('あ'), isFalse);
      expect(entity.toMarkup(), markup);
      expect(entity.toPlainText(), r'\frac12');
    });
    test('with terminator', () {
      final markup = r'\foobar{}';
      final result = parser.parse(markup);
      final entity = result.value as OrgEntity;
      expect(entity.contains('foobar'), isTrue);
      expect(entity.contains('あ'), isFalse);
      expect(entity.toMarkup(), markup);
      expect(entity.toPlainText(), r'\foobar');
    });
  });
}
