import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('markup', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.markups()).end();
    test('with line break', () {
      final markup = '''/foo
bar/''';
      var result = parser.parse(markup);
      final markupNode = result.value as OrgMarkup;
      expect(markupNode.contains('foo'), isTrue);
      expect(markupNode.toMarkup(), markup);
    });
  });
}
