import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.planningEntry()).end();
  test('planning line', () {
    final result =
        parser.parse('CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19]');
    final planningLine = result.value as OrgPlanningEntry;
    expect(planningLine.keyword.content, 'CLOCK:');
    final value = planningLine.value as OrgDateRangeTimestamp;
    expect(value.start.date.year, '2021');
  });
}
