import 'package:org_parser/src/util/util.dart';
import 'package:petitparser/petitparser.dart';

/// Grammar rules for the section query language described at
/// https://orgmode.org/manual/Matching-tags-and-properties.html
class OrgQueryGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(alternates).end();

  Parser alternates() => ref0(alternate) | ref0(selection);

  Parser alternate() => ref0(selection) & char('|') & ref0(alternates);

  Parser selection() =>
      ref0(explicitAnd) | ref0(implicitAnd) | ref0(simpleSelection);

  Parser explicitAnd() => ref0(simpleSelection) & char('&') & ref0(selection);

  Parser implicitAnd() => ref0(simpleSelection) & ref0(continuingSelection);

  Parser continuingSelection() =>
      ref0(continuingExplicitAnd) |
      ref0(continuingImplicitAnd) |
      ref0(continuingSimpleSelection);

  Parser continuingExplicitAnd() =>
      ref0(continuingSimpleSelection) & char('&') & ref0(selection);

  Parser continuingImplicitAnd() =>
      ref0(continuingSimpleSelection) & ref0(continuingSelection);

  Parser simpleSelection() => ref0(include) | ref0(exclude);

  Parser continuingSimpleSelection() => ref0(explicitInclude) | ref0(exclude);

  Parser include() => ref0(explicitInclude) | ref0(implicitInclude);

  Parser explicitInclude() => char('+') & ref0(element);

  Parser implicitInclude() => ref0(element);

  Parser exclude() => char('-') & ref0(element);

  // TODO(aaron): Support regex element: {^boss.*}
  Parser element() => ref0(propertyExpression) | ref0(tag);

  Parser tag() => pattern('a-zA-Z0-9_@#%').plusString('Tag expected');

  Parser propertyExpression() =>
      ref0(propertyName) & ref0(op) & ref0(propertyValue);

  Parser propertyName() => insignificantWhitespace()
      .neg()
      .plusLazy(ref0(op))
      .flatten('Property name expected');

  Parser op() =>
      string('<=') |
      string('=>') |
      string('>=') |
      string('=<') |
      string('<>') |
      string('!=') |
      string('==') |
      anyOf('<=>');

  // TODO(aaron): Support regex values (With={Sarah\|Denny}), dates
  // (SCHEDULED>="<2008-10-11>")
  Parser propertyValue() => ref0(numberValue) | ref0(stringValue);

  Parser numberValue() => digit().plusString();

  Parser stringValue() =>
      char('"') &
      char('"').neg().plusLazy(char('"')).flatten('String content expected') &
      char('"');
}
