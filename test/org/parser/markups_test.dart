import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('markups', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.markups()).end();
    test('with line break', () {
      final result = parser.parse('''/foo
bar/''');
      final markup = result.value as OrgMarkup;
      final content = markup.content.children.single as OrgPlainText;
      expect(content.content, 'foo\nbar');
      expect(markup.leadingDecoration, '/');
      expect(markup.trailingDecoration, '/');
      expect(markup.style, OrgStyle.italic);
    });
    test('nested markup', () {
      final result = parser.parse("~foo *bar* baz~");
      final markup = result.value as OrgMarkup;
      final nested =
          markup.find<OrgMarkup>((node) => node.style == OrgStyle.bold);
      expect(nested, isNotNull);
      expect(nested!.node.content.children.single.toMarkup(), 'bar');
      expect(nested.path.map((n) => n.toString()).toList(),
          ['OrgMarkup', 'OrgContent', 'OrgMarkup']);
    });
    test('double-nested markup', () {
      final result = parser.parse("~foo *bar /baz/ buzz* bazinga~");
      final markup = result.value as OrgMarkup;
      final nested =
          markup.find<OrgMarkup>((node) => node.style == OrgStyle.italic);
      expect(nested, isNotNull);
      expect(nested!.node.content.children.single.toMarkup(), 'baz');
      expect(nested.path.map((n) => n.toString()).toList(),
          ['OrgMarkup', 'OrgContent', 'OrgMarkup', 'OrgContent', 'OrgMarkup']);
    });
    test('with too many line breaks', () {
      final result = parser.parse('''/foo

bar/''');
      expect(result, isA<Failure>());
    });
  });
}
