import 'package:org_parser/src/todo/grammar.dart';
import 'package:org_parser/src/todo/model.dart';
import 'package:petitparser/petitparser.dart';

final orgTodo = TodoParser().build();

class TodoParser extends TodoGrammar {
  @override
  Parser workflow() => super.workflow().castList<List<dynamic>?>().map((items) {
        // Discard annotations for now
        final todo = items[0]
            ?.map((state) => state[0] as String)
            .toList(growable: false);
        final done = items[1]
            ?.map((state) => state[0] as String)
            .toList(growable: false);

        // Last todo state is considered done if no done states are provided
        if (done == null && todo != null && todo.isNotEmpty) {
          return OrgTodoStates(
            todo: todo.getRange(0, todo.length - 1),
            done: [todo.last],
          );
        }
        return OrgTodoStates(todo: todo, done: done);
      });
}
