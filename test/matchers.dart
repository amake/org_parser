import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

TypeMatcher<SeparatedList<R, S>> isSeparatedList<R, S>({
  List<R> elements = const [],
  List<S> separators = const [],
}) =>
    isA<SeparatedList<R, S>>()
        .having((list) => list.elements, 'elements', elements)
        .having((list) => list.separators, 'separators', separators);
