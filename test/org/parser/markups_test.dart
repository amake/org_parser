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
      expect(markup.content, 'foo\nbar');
      expect(markup.leadingDecoration, '/');
      expect(markup.trailingDecoration, '/');
      expect(markup.style, OrgStyle.italic);
    });
    test('with too many line breaks', () {
      final result = parser.parse('''/foo

bar/''');
      expect(result, isA<Failure>());
    });
  });
}
