import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('property', () {
    final grammar = OrgContentGrammarDefinition();
    final parser = grammar.buildFrom(grammar.property()).end();
    test('simple', () {
      final result = parser.parse(':foo: bar');
      expect(result.value, [
        '',
        [':', 'foo', ':'],
        ' bar',
        ''
      ]);
    });
    test('missing value', () {
      final result = parser.parse(':foo:');
      expect(result, isA<Failure>());
    });
    test('missing delimiter', () {
      final result = parser.parse(':foo:blah');
      expect(result, isA<Failure>(), reason: 'Delimiting space required');
    });
    test('line break', () {
      final result = parser.parse(''':foo:
bar''');
      expect(result, isA<Failure>(), reason: 'Value must be on same line');
    });
  });
}
