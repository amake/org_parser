import 'package:petitparser/petitparser.dart';

/// Grammar rules for file links, which are basically a mini-format of their own
class OrgFileLinkGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() =>
      ref0(scheme) &
      ref0(body) &
      (string('::') & ref0(extra)).pick(1).optional();

  Parser scheme() =>
      (string('file:') | string('attachment:') | anyOf('/.').and())
          .flatten('Expected link scheme');

  Parser body() =>
      any().starLazy(string('::') | endOfInput()).flatten('Expected link body');

  Parser extra() => any().starString('Expected link extra');
}
