import 'package:petitparser/petitparser.dart';

/// Returns a parser that transforms a successful parse result by removing the
/// elements at [indexes] of a list. Negative indexes can be used to access the
/// elements from the back of the list. Assumes this parser to be of type
/// `Parser<List<R>>`.
///
/// For example, the parser `letter().star().drop([0, -1])` returns everything
/// but the first and last letter parsed. For the input `'abc'` it returns
/// `['b']`.
///
/// Mirrors Parser.permute in PetitParser.
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
