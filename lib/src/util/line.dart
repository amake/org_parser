import 'package:org_parser/src/util/bof.dart';
import 'package:org_parser/src/util/lookbehind.dart';
import 'package:petitparser/petitparser.dart';

/// Returns a parser that matches the start of a line; this could be the
/// beginning of input, or the position following a line break.
Parser lineStart() => startOfInput() | was(Token.newlineParser());

/// Returns a parser that matches the end of a line; this could be the
/// end of input, or a line break.
Parser lineEnd() => Token.newlineParser() | endOfInput();
