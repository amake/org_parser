import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.planningLine()).end();
  test('planning line', () {
    final result = parser.parse(
        'CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49');
    final planningLine = result.value as OrgPlanningLine;
    expect(planningLine.keyword.content, 'CLOCK:');
    final text = planningLine.body.children.last as OrgPlainText;
    expect(text.content, ' =>  0:49');
  });
}
