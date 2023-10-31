import 'package:petitparser/petitparser.dart';

// Defined outside of grammar to avoid
// https://github.com/petitparser/dart-petitparser/issues/155
Parser<String> insignificantWhitespace() => anyOf(' \t');
