import 'package:org_parser/src/org/org.dart';
import 'package:org_parser/src/todo/todo.dart';
import 'package:test/test.dart';

void main() {
  final parser = org;
  group('cycle todo', () {
    group('todo states', () {
      final result = parser.parse('''* foo''');
      final doc = result.value as OrgDocument;
      final section = doc.sections[0];
      test('defaults', () {
        final todo = section.cycleTodo();
        expect(todo.toMarkup(), '* TODO foo');
        final done = todo.cycleTodo();
        expect(done.toMarkup(), '* DONE foo');
        final none = done.cycleTodo();
        expect(none.toMarkup(), '* foo');
      });
      test('custom settings', () {
        final todoStates = [
          OrgTodoStates(todo: ['A', 'B'], done: ['C', 'D'])
        ];
        final a = section.cycleTodo(todoStates: todoStates);
        expect(a.toMarkup(), '* A foo');
        final b = a.cycleTodo(todoStates: todoStates);
        expect(b.toMarkup(), '* B foo');
        final c = b.cycleTodo(todoStates: todoStates);
        expect(c.toMarkup(), '* C foo');
        final d = c.cycleTodo(todoStates: todoStates);
        expect(d.toMarkup(), '* D foo');
        final none = d.cycleTodo(todoStates: todoStates);
        expect(none.toMarkup(), '* foo');
      });
      test('repeated state', () {
        final todoStates = [
          OrgTodoStates(todo: ['A', 'A'])
        ];
        final a = section.cycleTodo(todoStates: todoStates);
        expect(a.toMarkup(), '* A foo');
        final a2 = a.cycleTodo(todoStates: todoStates);
        expect(a2.toMarkup(), '* A foo');
      });
      test('missing state', () {
        final a = section.cycleTodo(todoStates: [
          OrgTodoStates(todo: ['A'])
        ]);
        expect(a.toMarkup(), '* A foo');
        expect(
          () => a.cycleTodo(todoStates: [
            OrgTodoStates(todo: ['B'])
          ]),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('empty state', () {
        final todoStates = [OrgTodoStates()];
        final a = section.cycleTodo(todoStates: todoStates);
        expect(a.toMarkup(), '* foo');
        final a2 = a.cycleTodo(todoStates: todoStates);
        expect(a2.toMarkup(), '* foo');
      });
    });
    group('repeating todo', () {
      test('in headline', () {
        final now = DateTime(2024, 1, 2, 12, 34);
        final result = parser.parse('''* TODO foo <2024-01-01 Mon +1w>''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.cycleTodo(now: now);
        expect(updated.toMarkup(), '''* TODO foo <2024-01-08 Mon +1w>
  :PROPERTIES:
  :LAST_REPEAT: [2024-01-02 Tue 12:34]
  :END:
  - State "DONE"       from "TODO"      [2024-01-02 Tue 12:34]
''');
      });
      test('scheduled', () {
        final now = DateTime(2024, 1, 2, 12, 34);
        final result = parser.parse('''* TODO foo
  SCHEDULED: <2024-01-01 Mon +1w>''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.cycleTodo(now: now);
        expect(updated.toMarkup(), '''* TODO foo
  SCHEDULED: <2024-01-08 Mon +1w>
  :PROPERTIES:
  :LAST_REPEAT: [2024-01-02 Tue 12:34]
  :END:
  - State "DONE"       from "TODO"      [2024-01-02 Tue 12:34]
''');
      });
      test('with previous log', () {
        final now = DateTime(2024, 2, 3, 23, 45);
        final result = parser.parse('''* TODO foo
  SCHEDULED: <2024-01-01 Mon +1w>
  :PROPERTIES:
  :LAST_REPEAT: [2024-01-02 Tue 12:34]
  :END:
  - State "DONE"       from "TODO"      [2024-01-02 Tue 12:34]
''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.cycleTodo(now: now);
        expect(updated.toMarkup(), '''* TODO foo
  SCHEDULED: <2024-01-08 Mon +1w>
  :PROPERTIES:
  :LAST_REPEAT: [2024-02-03 Sat 23:45]
  :END:
  - State "DONE"       from "TODO"      [2024-02-03 Sat 23:45]
  - State "DONE"       from "TODO"      [2024-01-02 Tue 12:34]
''');
      });
    });
  });
  group('set property', () {
    group('add drawer', () {
      test('empty content', () {
        final result = parser.parse('''* TODO foo''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''* TODO foo
  :PROPERTIES:
  :PRIORITY: A
  :END:
''');
      });
      test('higher level', () {
        final result = parser.parse('''** TODO foo''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '   ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''** TODO foo
   :PROPERTIES:
   :PRIORITY: A
   :END:
''');
      });
      test('with paragraph', () {
        final result = parser.parse('''* TODO foo
buzz bazz''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''* TODO foo
  :PROPERTIES:
  :PRIORITY: A
  :END:
buzz bazz''');
      });
      test('with SCHEDULED:', () {
        final result = parser.parse('''* TODO foo
  SCHEDULED: <2024-01-01 Mon>''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''* TODO foo
  SCHEDULED: <2024-01-01 Mon>
  :PROPERTIES:
  :PRIORITY: A
  :END:
''');
      });
      test('with SCHEDULED: with newline', () {
        final result = parser.parse('''* TODO foo
  SCHEDULED: <2024-01-01 Mon>
''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''* TODO foo
  SCHEDULED: <2024-01-01 Mon>
  :PROPERTIES:
  :PRIORITY: A
  :END:
''');
      });
      test('with SCHEDULED: with more content', () {
        final result = parser.parse('''* TODO foo
  SCHEDULED: <2024-01-01 Mon>
foo
''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(
            updated.toMarkup(),
            '''* TODO foo
  SCHEDULED: <2024-01-01 Mon>
  :PROPERTIES:
  :PRIORITY: A
  :END:
foo
''',
// TODO(aaron): Get full fidelity on this
            skip: true);
      });
      test('with invalid SCHEDULED:', () {
        final result = parser.parse('''* TODO foo

  SCHEDULED: <2024-01-01 Mon>''');
        final doc = result.value as OrgDocument;
        final section = doc.sections[0];
        final updated = section.setProperty(
          OrgProperty(
              '  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
        );
        expect(updated.toMarkup(), '''* TODO foo
  :PROPERTIES:
  :PRIORITY: A
  :END:

  SCHEDULED: <2024-01-01 Mon>''');
      });
    });
    test('add property', () {
      final result = parser.parse('''* TODO foo
  :PROPERTIES:
  :END:
''');
      final doc = result.value as OrgDocument;
      final section = doc.sections[0];
      final updated = section.setProperty(
        OrgProperty('  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
      );
      expect(updated.toMarkup(), '''* TODO foo
  :PROPERTIES:
  :PRIORITY: A
  :END:
''');
    });
    test('set property', () {
      final result = parser.parse('''* TODO foo
  :PROPERTIES:
  :PRIORITY: B
  :END:
''');
      final doc = result.value as OrgDocument;
      final section = doc.sections[0];
      final updated = section.setProperty(
        OrgProperty('  ', ':PRIORITY:', OrgContent([OrgPlainText(' A')]), '\n'),
      );
      expect(updated.toMarkup(), '''* TODO foo
  :PROPERTIES:
  :PRIORITY: A
  :END:
''');
    });
  });
}
