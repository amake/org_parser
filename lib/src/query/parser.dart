import 'package:org_parser/src/query/query.dart';
import 'package:petitparser/petitparser.dart';

final orgQuery = OrgQueryParserDefinition().build();

class OrgQueryParserDefinition extends OrgQueryGrammarDefinition {
  @override
  Parser alternate() => super.alternate().map((value) => OrgQueryOrMatcher([
        value[0] as OrgQueryMatcher,
        value[2] as OrgQueryMatcher,
      ]));

  @override
  Parser explicitAnd() =>
      super.explicitAnd().map((value) => OrgQueryAndMatcher([
            value[0] as OrgQueryMatcher,
            value[2] as OrgQueryMatcher,
          ]));

  @override
  Parser implicitAnd() => super
      .implicitAnd()
      .castList<OrgQueryMatcher>()
      .map((value) => OrgQueryAndMatcher(value));

  @override
  Parser continuingExplicitAnd() =>
      super.continuingExplicitAnd().map((value) => OrgQueryAndMatcher([
            value[0] as OrgQueryMatcher,
            value[2] as OrgQueryMatcher,
          ]));

  @override
  Parser continuingImplicitAnd() => super
      .continuingImplicitAnd()
      .castList<OrgQueryMatcher>()
      .map((value) => OrgQueryAndMatcher(value));

  @override
  Parser explicitInclude() => super.explicitInclude().map((value) => value[1]);

  @override
  Parser exclude() => super
      .exclude()
      .map((value) => OrgQueryNotMatcher(value[1] as OrgQueryMatcher));

  @override
  Parser tag() =>
      super.tag().cast<String>().map((value) => OrgQueryTagMatcher(value));

  @override
  Parser propertyExpression() =>
      super.propertyExpression().map((value) => OrgQueryPropertyMatcher(
            property: value[0] as String,
            operator: value[1] as String,
            value: value[2],
          ));

  @override
  Parser numberValue() =>
      super.numberValue().cast<String>().map((value) => num.parse(value));

  @override
  Parser stringValue() => super.stringValue().map((value) => value[1]);
}
