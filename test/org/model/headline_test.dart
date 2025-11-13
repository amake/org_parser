import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/todo/todo.dart';
import 'package:test/test.dart';

void main() {
  final parser = org;
  group('cycle todo', () {
    final result = parser.parse('''* foo''');
    final doc = result.value as OrgDocument;
    final section = doc.sections[0];
    final headline = section.headline;
    test('defaults', () {
      final todo = headline.cycleTodo();
      expect(todo.toMarkup(), '* TODO foo');
      final done = todo.cycleTodo();
      expect(done.toMarkup(), '* DONE foo');
      final none = done.cycleTodo();
      expect(none.toMarkup(), '* foo');
    });
    test('custom settings', () {
      final todoSettings = [
        OrgTodoStates(todo: ['A', 'B'], done: ['C', 'D'])
      ];
      final a = headline.cycleTodo(todoSettings);
      expect(a.toMarkup(), '* A foo');
      final b = a.cycleTodo(todoSettings);
      expect(b.toMarkup(), '* B foo');
      final c = b.cycleTodo(todoSettings);
      expect(c.toMarkup(), '* C foo');
      final d = c.cycleTodo(todoSettings);
      expect(d.toMarkup(), '* D foo');
      final none = d.cycleTodo(todoSettings);
      expect(none.toMarkup(), '* foo');
    });
    test('repeated state', () {
      final todoSettings = [
        OrgTodoStates(todo: ['A', 'A'])
      ];
      final a = headline.cycleTodo(todoSettings);
      expect(a.toMarkup(), '* A foo');
      final a2 = a.cycleTodo(todoSettings);
      expect(a2.toMarkup(), '* A foo');
    });
    test('missing state', () {
      final a = headline.cycleTodo([
        OrgTodoStates(todo: ['A'])
      ]);
      expect(a.toMarkup(), '* A foo');
      expect(
        () => a.cycleTodo([
          OrgTodoStates(todo: ['B'])
        ]),
        throwsA(isA<ArgumentError>()),
      );
    });
    test('empty state', () {
      final todoSettings = [OrgTodoStates()];
      final a = headline.cycleTodo(todoSettings);
      expect(a.toMarkup(), '* foo');
      final a2 = a.cycleTodo(todoSettings);
      expect(a2.toMarkup(), '* foo');
    });
  });
}
