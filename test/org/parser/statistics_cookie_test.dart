import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('markups', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.statsCookie()).end();
    group('percentage', () {
      test('simple', () {
        final result =
            parser.parse('[50%]').value as OrgStatisticsPercentageCookie;
        expect(result.leading, '[');
        expect(result.percentage, '50');
        expect(result.suffix, '%');
        expect(result.trailing, ']');
      });
      test('empty', () {
        final result =
            parser.parse('[%]').value as OrgStatisticsPercentageCookie;
        expect(result.leading, '[');
        expect(result.percentage, '');
        expect(result.suffix, '%');
        expect(result.trailing, ']');
      });
    });
    group('fraction', () {
      test('simple', () {
        final result =
            parser.parse('[1/2]').value as OrgStatisticsFractionCookie;
        expect(result.leading, '[');
        expect(result.numerator, '1');
        expect(result.separator, '/');
        expect(result.denominator, '2');
        expect(result.trailing, ']');
      });
      test('empty', () {
        final result = parser.parse('[/]').value as OrgStatisticsFractionCookie;
        expect(result.leading, '[');
        expect(result.numerator, '');
        expect(result.separator, '/');
        expect(result.denominator, '');
        expect(result.trailing, ']');
      });
      test('partial', () {
        final result =
            parser.parse('[/2]').value as OrgStatisticsFractionCookie;
        expect(result.leading, '[');
        expect(result.numerator, '');
        expect(result.separator, '/');
        expect(result.denominator, '2');
        expect(result.trailing, ']');
      });
    });
  });
}
