import 'package:org_parser/src/org/org.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('timestamps', () {
    final definition = OrgContentParserDefinition();
    final parser = definition.buildFrom(definition.timestamp()).end();
    test('date', () {
      final result =
          parser.parse('<2020-03-12 Wed>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNull);
      expect(result.repeaterOrDelay, isEmpty);
      expect(result.suffix, '>');
    });
    test('date without day of week', () {
      final result = parser.parse('<2020-03-12>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.time, isNull);
      expect(result.repeaterOrDelay, isEmpty);
      expect(result.suffix, '>');
    });
    test('date and time', () {
      final result =
          parser.parse('<2020-03-12 Wed 8:34>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.repeaterOrDelay, isEmpty);
      expect(result.suffix, '>');
    });
    test('date and time without day of week', () {
      final result =
          parser.parse('<2020-03-12 8:34>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.repeaterOrDelay, isEmpty);
      expect(result.suffix, '>');
    });
    test('with repeater', () {
      final result =
          parser.parse('<2020-03-12 Wed 8:34 +1w>').value as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.repeaterOrDelay, ['+1w']);
      expect(result.suffix, '>');
    });
    test('with multiple repeaters', () {
      final result = parser.parse('<2020-03-12 Wed 8:34 +1w --2d>').value
          as OrgSimpleTimestamp;
      expect(result.prefix, '<');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '8');
      expect(result.time!.minute, '34');
      expect(result.repeaterOrDelay, ['+1w', '--2d']);
      expect(result.suffix, '>');
    });
    test('inactive', () {
      final result = parser.parse('[2020-03-12 Wed 18:34 .+1w --12d]').value
          as OrgSimpleTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.time, isNotNull);
      expect(result.time!.hour, '18');
      expect(result.time!.minute, '34');
      expect(result.repeaterOrDelay, ['.+1w', '--12d']);
      expect(result.suffix, ']');
    });
    test('time range', () {
      final result = parser
          .parse('[2020-03-12 Wed 18:34-19:35 .+1w --12d]')
          .value as OrgTimeRangeTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, 'Wed');
      expect(result.timeStart.hour, '18');
      expect(result.timeStart.minute, '34');
      expect(result.timeEnd.hour, '19');
      expect(result.timeEnd.minute, '35');
      expect(result.repeaterOrDelay, ['.+1w', '--12d']);
      expect(result.suffix, ']');
    });
    test('time range without day of week', () {
      final result = parser.parse('[2020-03-12 18:34-19:35 .+1w --12d]').value
          as OrgTimeRangeTimestamp;
      expect(result.prefix, '[');
      expect(result.date.year, '2020');
      expect(result.date.month, '03');
      expect(result.date.day, '12');
      expect(result.date.dayName, isNull);
      expect(result.timeStart.hour, '18');
      expect(result.timeStart.minute, '34');
      expect(result.timeEnd.hour, '19');
      expect(result.timeEnd.minute, '35');
      expect(result.repeaterOrDelay, ['.+1w', '--12d']);
      expect(result.suffix, ']');
    });
    test('date range', () {
      final result = parser
          .parse(
              '[2020-03-11 Wed 18:34 .+1w --12d]--[2020-03-12 Wed 18:34 .+1w --12d]')
          .value as OrgDateRangeTimestamp;
      expect(result.start.prefix, '[');
      expect(result.start.date.year, '2020');
      expect(result.start.date.month, '03');
      expect(result.start.date.day, '11');
      expect(result.start.date.dayName, 'Wed');
      expect(result.start.time!.hour, '18');
      expect(result.start.time!.minute, '34');
      expect(result.start.repeaterOrDelay, ['.+1w', '--12d']);
      expect(result.start.suffix, ']');
      expect(result.delimiter, '--');
      expect(result.end.prefix, '[');
      expect(result.end.date.year, '2020');
      expect(result.end.date.month, '03');
      expect(result.end.date.day, '12');
      expect(result.end.date.dayName, 'Wed');
      expect(result.end.time!.hour, '18');
      expect(result.end.time!.minute, '34');
      expect(result.end.repeaterOrDelay, ['.+1w', '--12d']);
      expect(result.end.suffix, ']');
    });
    test('sexp', () {
      final result =
          parser.parse('<%%(what (the (f))) foo>').value as OrgDiaryTimestamp;
      expect(result.content, '<%%(what (the (f))) foo>');
    });
  });
}
