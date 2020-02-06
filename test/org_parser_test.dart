import 'package:org_parser/org_parser.dart';
import 'package:test/test.dart';

void main() {
  final grammar = OrgGrammar();
  test('parse a header', () {
    final result = grammar.parse('* Title');
    expect(result.value, [
      [
        ['*', null, 'Title'],
        null
      ]
    ]);
  });
  test('parse a todo header', () {
    final result = grammar.parse('* TODO Title');
    expect(result.value, [
      [
        ['*', 'TODO', 'Title'],
        null
      ]
    ]);
  });
  test('parse a section', () {
    final result = grammar.parse('''* Title
  Content1
  Content2''');
    expect(result.value, [
      [
        ['*', null, 'Title'],
        '  Content1\n  Content2'
      ]
    ]);
  });
}
