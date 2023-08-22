import 'package:petitparser/petitparser.dart';

Parser<T> resultPredicate<T>(
  Parser<T> child,
  Predicate predicate, [
  String message = 'Predicate failed',
]) =>
    ResultPredicateParser(child, predicate, message);

typedef Predicate = bool Function(String buffer, int from, int to);

class ResultPredicateParser<T> extends DelegateParser<T, T> {
  ResultPredicateParser(
    Parser<T> child,
    this.predicate,
    this.message,
  ) : super(child);

  final Predicate predicate;
  final String message;

  @override
  Result<T> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result is Success) {
      if (predicate(context.buffer, context.position, result.position)) {
        return result;
      } else {
        return result.failure(message);
      }
    }
    return result;
  }

  @override
  Parser<T> copy() => ResultPredicateParser(delegate, predicate, message);
}
