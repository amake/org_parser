import 'package:org_parser/org_parser.dart';
import 'package:org_parser/src/parser.dart';
import 'package:test/test.dart';

void main() {
  final grammar = OrgGrammar();
  final parser = OrgParser();
  test('parse content', () {
    final result = grammar.parse('''foo
bar
''');
    expect(result.value, ['foo\nbar\n', []]);
  });
  test('parse a header', () {
    final result = grammar.parse('* Title');
    expect(result.value, [
      null,
      [
        [
          ['*', null, null, 'Title', null],
          null
        ]
      ]
    ]);
  });
  test('parse a todo header', () {
    final result = grammar.parse('* TODO Title');
    expect(result.value, [
      null,
      [
        [
          ['*', 'TODO', null, 'Title', null],
          null
        ]
      ]
    ]);
  });
  test('parse a section', () {
    final result = grammar.parse('''* Title
  Content1
  Content2''');
    expect(result.value, [
      null,
      [
        [
          ['*', null, null, 'Title', null],
          'Content1\n'
              '  Content2'
        ]
      ]
    ]);
  });
  test('valid headers', () {
    for (final valid in [
      '* ',
      '** DONE',
      '*** Some e-mail',
      '**** TODO [#A] COMMENT Title :tag:a2%:',
    ]) {
      expect(grammar.parse(valid).isSuccess, true);
    }
  });
  test('example document', () {
    final doc = '''An introduction.

* A Headline

  Some text. *bold*

** Sub-Topic 1

** Sub-Topic 2

*** Additional entry''';
    expect(grammar.parse(doc).isSuccess, true);
    final parsed = parser.parse(doc);
    expect(parsed.isSuccess, true);
    final List values = parsed.value;
    expect(values[0], 'An introduction.\n\n');
    final List sections = values[1];
    final topSection = sections[0];
    expect(topSection.headline.title, 'A Headline');
    expect(topSection.children.length, 2);
  });
}
