import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('Comments', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.comment()).end();
    test('simple', () {
      final markup = '# foo bar';
      final result = parser.parse(markup);
      final comment = result.value as OrgComment;
      expect(comment.contains('foo'), isTrue);
      expect(comment.contains('あ'), isFalse);
      expect(comment.toMarkup(), markup);
    });
  });
}
