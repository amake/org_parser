import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final definition = OrgContentParserDefinition();
  final parser = definition.buildFrom(definition.planningLine()).end();
  test('planning line', () {
    final markup =
        'CLOCK: [2021-01-23 Sat 09:30]--[2021-01-23 Sat 10:19] =>  0:49';
    final result = parser.parse(markup);
    final planningLine = result.value as OrgPlanningLine;
    expect(planningLine.contains('CLOCK'), isTrue);
    expect(planningLine.contains('あ'), isFalse);
    expect(planningLine.toMarkup(), markup);
  });
}
