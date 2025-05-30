import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('timestamps', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.timestamp()).end();
    test('date', () {
      final markup = '<2020-03-12 Wed>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12));
      expect(result.toMarkup(), markup);
    });
    test('date and time', () {
      final markup = '<2020-03-12 Wed 8:34>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
    });
    test('with repeater', () {
      final markup = '<2020-03-12 Wed 8:34 +1w>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('+1w'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
    });
    test('with repeater (min/max)', () {
      final markup = '<2020-03-12 Wed 8:34 +1w/2w>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('+1w/2w'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
    });
    test('with multiple repeaters', () {
      final markup = '<2020-03-12 Wed 8:34 +1w --2d>';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('+1w'), isTrue);
      expect(result.contains('--2d'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isTrue);
      expect(result.dateTime, DateTime(2020, 03, 12, 08, 34));
      expect(result.toMarkup(), markup);
    });
    test('inactive', () {
      final markup = '[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgSimpleTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.dateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.toMarkup(), markup);
    });
    test('time range', () {
      final markup = '[2020-03-12 Wed 18:34-19:35 .+1w --12d]';
      final result = parser.parse(markup).value as OrgTimeRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.startDateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.endDateTime, DateTime(2020, 03, 12, 19, 35));
      expect(result.toMarkup(), markup);
    });
    test('date range', () {
      final markup =
          '[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]';
      final result = parser.parse(markup).value as OrgDateRangeTimestamp;
      expect(result.contains('2020'), isTrue);
      expect(result.contains('11'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('Wed'), isTrue);
      expect(result.contains('.+1w'), isTrue);
      expect(result.contains('--12d'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.isActive, isFalse);
      expect(result.start.dateTime, DateTime(2020, 03, 11, 18, 34));
      expect(result.end.dateTime, DateTime(2020, 03, 12, 18, 34));
      expect(result.toMarkup(), markup);
    });
    test('sexp', () {
      final markup = '<%%(what (the (f)))>';
      final result = parser.parse(markup).value as OrgDiaryTimestamp;
      expect(result.contains('what'), isTrue);
      expect(result.contains('あ'), isFalse);
      expect(result.toMarkup(), markup);
    });
    group("generic timestamp tests", () {
      test('OrgSimeTimestamp parse', () {
        final markup = '<2025-05-30>';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result is OrgSimpleTimestamp, isTrue);
        expect(result is OrgDateRangeTimestamp, isFalse);
        expect(result is OrgTimeRangeTimestamp, isFalse);
      });
      test('OrgSimeTimestamp parse', () {
        final markup = '<2025-05-30 15:00-16:00>';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result is OrgTimeRangeTimestamp, isTrue);
        expect(result is OrgSimpleTimestamp, isFalse);
        expect(result is OrgDateRangeTimestamp, isFalse);
      });
      test('OrgSimeTimestamp parse', () {
        final markup = '<2025-05-30>--<2025-06-30>';
        final result = parser.parse(markup).value as OrgTimestamp;

        expect(result is OrgDateRangeTimestamp, isTrue);
        expect(result is OrgSimpleTimestamp, isFalse);
        expect(result is OrgTimeRangeTimestamp, isFalse);
      });
    });
  });
}
