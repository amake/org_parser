import 'package:org_parser/src/util/bof.dart';
import 'package:org_parser/src/util/lookbehind.dart';
import 'package:petitparser/petitparser.dart';

Parser lineStart() => startOfInput() | was(Token.newlineParser());

Parser lineEnd() => Token.newlineParser() | endOfInput();
