import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/todo/todo.dart';
import 'package:test/test.dart';

void main() {
  group('todo keywords', () {
    final parser = OrgParserDefinition(todoStates: [
      OrgTodoStates(todo: ['FOO'], done: ['BAR'])
    ]).build();
    test('custom keywords', () {
      final doc = parser.parse('''
* FOO [#A] foo bar
  buzz baz
* BAR [#B] bar foo
  baz buzz''').value as OrgDocument;
      expect(doc.sections[0].headline.keyword?.value, 'FOO');
      expect(doc.sections[0].headline.keyword?.done, isFalse);
      expect(doc.sections[1].headline.keyword?.value, 'BAR');
      expect(doc.sections[1].headline.keyword?.done, isTrue);
    });
    test('unrecognized keyword', () {
      final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
      expect(doc.sections[0].headline.keyword?.value, isNull);
      expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
    });
    test('empty states object', () {
      final parser = OrgParserDefinition(todoStates: [OrgTodoStates()]).build();
      final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
      expect(doc.sections[0].headline.keyword?.value, isNull);
      expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
    });
    test('empty list of states objects', () {
      final parser = OrgParserDefinition(todoStates: []).build();
      final doc = parser.parse('''* TODO [#A] foo bar
        baz buzz''').value as OrgDocument;
      expect(doc.sections[0].headline.keyword?.value, isNull);
      expect(doc.sections[0].headline.rawTitle, 'TODO [#A] foo bar');
    });
  });
}
