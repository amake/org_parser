import 'package:collection/collection.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

Matcher isSeparatedList({List<String>? elements, List<String>? separators}) =>
    _SeparatedListMatcher(elements, separators);

class _SeparatedListMatcher extends Matcher {
  const _SeparatedListMatcher(this.elements, this.separators);

  final List<String>? elements;
  final List<String>? separators;

  @override
  Description describe(Description description) {
    return description;
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! SeparatedList) return false;

    var result = true;

    if (elements != null) {
      result &= ListEquality<dynamic>().equals(elements, item.elements);
    }

    if (separators != null) {
      result &= ListEquality<dynamic>().equals(separators, item.separators);
    }

    return result;
  }
}
