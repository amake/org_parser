import 'package:org_parser/src/util/bof.dart';
import 'package:org_parser/src/util/lookbehind.dart';
import 'package:petitparser/petitparser.dart';

/// Returns a parser that matches the start of a line; this could be the
/// beginning of input, or the position following a line break.
Parser lineStart() => startOfInput() | was(newline());

/// Returns a parser that matches the end of a line; this could be the
/// end of input, or a line break.
Parser lineEnd() => newline() | endOfInput();

/// Returns a parser that matches everything up to and including the end of the
/// line.
Parser lineTrailing() => any().starLazy(lineEnd()) & lineEnd();
