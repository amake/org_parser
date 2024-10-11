import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('Comment', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.comment()).end();
    test('simple', () {
      final result = parser.parse('# foo bar');
      final comment = result.value as OrgComment;
      expect(comment.indent, '');
      expect(comment.start, '# ');
      expect(comment.content, 'foo bar');
    });
  });
}
