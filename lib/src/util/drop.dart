import 'package:petitparser/petitparser.dart';

Parser<List<R>> drop<R>(Parser<R> parser, List<int> indexes) {
  return parser.castList<R>().map<List<R>>((list) {
    var result = list;
    for (var index in indexes.reversed) {
      if (index < 0) {
        index = list.length + index;
      }
      result = result
          .sublist(0, index)
          .followedBy(result.sublist(index + 1))
          .toList();
    }
    return result;
  });
}
