import 'package:org_parser/org_parser.dart';
import 'package:petitparser/petitparser.dart';

final defaultTodoStates = OrgTodoStates(todo: ['TODO'], done: ['DONE']);

const _todoMetaKeywords = ['#+TODO:', '#+SEQ_TODO:', '#+TYP_TODO:'];

/// Extracts the TODO settings from `#+TODO:` and equivalent meta keywords in
/// the given [tree].
List<OrgTodoStates> extractTodoSettings(
  OrgTree tree,
) {
  final results = <OrgTodoStates>[];
  tree.visit<OrgMeta>((meta) {
    if (_todoMetaKeywords.contains(meta.keyword.toUpperCase())) {
      final trailing = meta.trailing.trim();
      if (trailing.isEmpty) return true;
      final parsed = orgTodo.parse(trailing);
      if (parsed is Failure) {
        return true;
      }
      results.add(parsed.value as OrgTodoStates);
    }
    return true;
  });
  return results;
}

/// A class representing the TODO states a la `org-todo-keywords`. Extract such
/// states embedded in a document using [extractTodoSettings].
class OrgTodoStates {
  final List<String> todo;
  final List<String> done;

  OrgTodoStates({Iterable<String>? todo, Iterable<String>? done})
      : todo = List.unmodifiable(todo ?? <String>[]),
        done = List.unmodifiable(done ?? <String>[]);

  bool get isEmpty => todo.isEmpty && done.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => 'TodoStates[${todo.join(' ')} | ${done.join(' ')}]';

  @override
  bool operator ==(Object other) =>
      other is OrgTodoStates &&
      _listEquals(todo, other.todo) &&
      _listEquals(done, other.done);

  @override
  int get hashCode => Object.hash(Object.hashAll(todo), Object.hashAll(done));
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
