import 'package:petitparser/petitparser.dart';

extension DropParserExtension<R> on Parser<R> {
  /// Returns a parser that transforms a successful parse result by removing the
  /// elements at [indexes] of a list. Negative indexes can be used to access
  /// the elements from the back of the list.
  ///
  /// For example, the parser `letter().star().drop([0, -1])` returns everything
  /// but the first and last letter parsed. For the input `'abc'` it returns
  /// `['b']`.
  ///
  /// Mirrors Parser.permute in PetitParser.
  Parser<List<dynamic>> drop(List<int> indexes) =>
      castList<dynamic>().map((list) {
        final result = list.toList();
        for (final index in indexes
          ..sort()
          ..reversed) {
          result.removeAt((index + list.length) % list.length);
        }
        return result;
      });

  Parser<List<dynamic>> drop1(int index) => castList<dynamic>().map((list) {
        final result = list.toList();
        result.removeAt((index + list.length) % list.length);
        return result;
      });
}
